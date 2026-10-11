"""Apply a release patch to isolated upstream files and compare with the local sources."""
import argparse
from pathlib import Path
import re
import subprocess
import tarfile
import tempfile

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("project", choices=["sm64coopdx", "SkyCraft"])
parser.add_argument("upstream", type=Path)
args = parser.parse_args()
root = Path(__file__).resolve().parent.parent
patch = root / "patches" / ("sm64coopdx.patch" if args.project == "sm64coopdx" else "skycraft.patch")
paths = re.findall(r"^diff --git a/(.+) b/.*$", patch.read_text(encoding="utf-8"), re.M)
with tempfile.TemporaryDirectory(prefix="mariocraft-patch-") as temporary:
    checkout = Path(temporary).resolve()
    with tarfile.open(args.upstream) as archive:
        members = {m.name.split("/", 1)[1]: m for m in archive.getmembers() if m.isfile() and "/" in m.name}
        for name in paths:
            target = (checkout / name).resolve()
            if not target.is_relative_to(checkout):
                raise SystemExit(f"Patch path escapes checkout: {name}")
            if name in members:
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_bytes(archive.extractfile(members[name]).read())
    subprocess.run(["git", "apply", "--check", str(patch)], cwd=checkout, check=True)
    subprocess.run(["git", "apply", "--whitespace=nowarn", str(patch)], cwd=checkout, check=True)
    for name in paths:
        expected = (root / args.project / name).read_text(encoding="utf-8")
        actual = (checkout / name).read_text(encoding="utf-8")
        if actual != expected:
            raise SystemExit(f"Patched source differs: {name}")
    print(f"PASS: {patch.name} reproduces {len(paths)} source files from upstream")
