"""Refresh a project's source patch from its pinned upstream archive and local source.

The generated game directories are ignored by Git. Run this after source changes
so install.sh can reproduce them. ROMs and build outputs are never read.
"""
import argparse
import difflib
from pathlib import Path
import re
import subprocess
import tarfile
import tempfile

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("project", choices=["sm64coopdx", "SkyCraft"])
parser.add_argument("upstream", type=Path, help="Pinned release's original .tar.gz")
parser.add_argument("--add", nargs="*", default=[], help="New paths relative to the project")
parser.add_argument("--base-ref", help="Optional Git revision holding the previous patch")
args = parser.parse_args()
root = Path(__file__).resolve().parent.parent
patch = root / "patches" / ("sm64coopdx.patch" if args.project == "sm64coopdx" else "skycraft.patch")
previous = (subprocess.check_output(["git", "show", f"{args.base_ref}:patches/{patch.name}"], cwd=root).decode("utf-8")
    if args.base_ref else patch.read_text(encoding="utf-8"))
sections = {}
for section in re.split(r"(?=^diff --git )", previous, flags=re.M):
    match = re.match(r"diff --git a/(.+) b/.*", section)
    if match:
        sections[match.group(1)] = section
paths = list(sections)
paths.extend(sorted(set(args.add) - sections.keys()))
with tarfile.open(args.upstream) as archive:
    members = {m.name.split("/", 1)[1]: m for m in archive.getmembers() if m.isfile() and "/" in m.name}
    # A reverse check only checks the old hunks; it misses edits elsewhere in the same file.
    # Materialize the previous patch from upstream and compare whole files instead.
    with tempfile.TemporaryDirectory(prefix="mariocraft-previous-") as temporary:
        checkout = Path(temporary).resolve()
        for name in sections:
            target = (checkout / name).resolve()
            if not target.is_relative_to(checkout):
                raise SystemExit(f"Patch path escapes checkout: {name}")
            if name in members:
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_bytes(archive.extractfile(members[name]).read())
        subprocess.run(["git", "apply", "--whitespace=nowarn", "-"], input=previous.encode("utf-8"), cwd=checkout, check=True)
        prior_sources = {name: (checkout / name).read_text(encoding="utf-8") for name in sections}
    output = []
    for name in sorted(paths):
        source = root / args.project / name
        if not source.is_file():
            raise SystemExit(f"Missing local source: {source}")
        member = members.get(name)
        old = archive.extractfile(member).read().decode("utf-8").replace("\r\n", "\n") if member else ""
        new = source.read_text(encoding="utf-8")
        if old == new:
            continue
        section = sections.get(name)
        if section and prior_sources[name] == new:
            output.append(section)
            continue
        output.append(f"diff --git a/{name} b/{name}\n")
        if member is None:
            output.append("new file mode 100644\n")
        for line in difflib.unified_diff(old.splitlines(keepends=True), new.splitlines(keepends=True),
            fromfile=f"a/{name}" if member else "/dev/null", tofile=f"b/{name}"):
            output.append(line if line.endswith("\n") else line + "\n\\ No newline at end of file\n")
patch.write_text("".join(output), encoding="utf-8", newline="\n")
print(f"Refreshed {patch.name}: {len(paths)} source paths")
