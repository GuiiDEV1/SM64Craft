"""Package only a binary delta against the pinned official Windows release.

Build the patched native source WITHOUT a ROM first. Developer requirement:
Python 3.12 with bsdiff4. No executable or ROM is copied into the mod resources.
"""
import argparse
import bz2
import gzip
import hashlib
import json
from pathlib import Path
import struct
import zipfile
import re
import bsdiff4

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("upstream", type=Path)
parser.add_argument("build", type=Path)
parser.add_argument("output", type=Path)
args = parser.parse_args()
root = Path(__file__).resolve().parent.parent
commit = "8cd6e5977d9f920d51ca71f2c61801d019ed79c6"
archive_sha = "2a98c40acb2a46d30cde89f3072c039b641dbdf977985f9e82a040615f1b2381"
sha = lambda data: hashlib.sha256(data).hexdigest()
if sha(args.upstream.read_bytes()) != archive_sha:
    raise SystemExit("Official release archive hash mismatch")
source = args.build.resolve().parents[1]
if any(source.glob("baserom.*")):
    raise SystemExit("Release native source must have been built without a ROM")
source_patch = root / "patches/sm64coopdx.patch"
patched_paths = re.findall(r"^diff --git a/(.+) b/.*$", source_patch.read_text(encoding="utf-8"), re.M)
required_capture = {"src/pc/gfx/gfx_dxgi.cpp", "src/pc/gfx/gfx_direct3d11.cpp", "src/pc/gfx/gfx_sdl.c"}
if not required_capture.issubset(patched_paths):
    raise SystemExit("Native source patch is missing required video capture hooks")
# A checkout nested inside another Git repository can make git apply silently
# skip paths. Require all patched source files to actually match the local tree.
for relative in patched_paths:
    built_source = source / relative
    expected_source = root / "sm64coopdx" / relative
    if not built_source.is_file() or built_source.read_text(encoding="utf-8") != expected_source.read_text(encoding="utf-8"):
        raise SystemExit(f"Patched native source is missing or stale: {relative}")
with zipfile.ZipFile(args.upstream) as archive:
    base = archive.read("sm64coopdx.exe")
    # Every runtime asset comes from the official download. Refuse to silently
    # lose custom runtime assets; those would need their own verified delta.
    for name in ("dynos", "lang", "mods", "palettes"):
        for file in (args.build / name).rglob("*"):
            if file.is_file():
                relative = file.relative_to(args.build).as_posix()
                official = archive.read(relative) if relative in archive.namelist() else None
                local = file.read_bytes()
                # Git's Windows checkout converts text line endings. Keep the
                # official text files when their content is otherwise identical.
                same = official == local
                if official is not None and file.suffix in (".ini", ".lua"):
                    same = official.replace(b"\r\n", b"\n") == local.replace(b"\r\n", b"\n")
                if not same:
                    raise SystemExit(f"Runtime asset differs from official archive: {relative}")
    # The unmodified updater is supplied by the official release; recompiling
    # it locally may change compiler metadata without changing functionality.
    for name in ("discord_game_sdk.dll",):
        if (args.build / name).read_bytes() != archive.read(name):
            raise SystemExit(f"Runtime dependency differs from official archive: {name}")
target = (args.build / "sm64coopdx.exe").read_bytes()
if "Local\\MarioCraftFrame_v2".encode("utf-16-le") not in target:
    raise SystemExit("Native executable does not contain the MarioCraft frame bridge; rebuild it")
print(f"Generating delta: {len(base):,} -> {len(target):,} bytes", flush=True)
delta = bsdiff4.diff(base, target)
if bsdiff4.patch(base, delta) != target:
    raise SystemExit("Binary delta round trip failed")

def bsd_int(data):
    value = int.from_bytes(data, "little")
    return -(value & ((1 << 63) - 1)) if value >> 63 else value

ctrl_size, diff_size, target_size = [bsd_int(delta[i:i+8]) for i in (8, 16, 24)]
ctrl = bz2.decompress(delta[32:32+ctrl_size])
diff = bz2.decompress(delta[32+ctrl_size:32+ctrl_size+diff_size])
extra = bz2.decompress(delta[32+ctrl_size+diff_size:])
if len(ctrl) % 24 or target_size != len(target):
    raise SystemExit("Invalid bsdiff4 output")
args.output.mkdir(parents=True, exist_ok=True)
patch_path = args.output / "native-delta.gz"
with patch_path.open("wb") as file, gzip.GzipFile(fileobj=file, mode="wb", mtime=0) as out:
    out.write(b"MCDIFF01")
    out.write(struct.pack("<qq", len(base), len(target)))
    out.write(bytes.fromhex(sha(base)) + bytes.fromhex(sha(target)))
    out.write(struct.pack("<q", len(ctrl) // 24))
    diff_pos = extra_pos = 0
    for pos in range(0, len(ctrl), 24):
        x, y, z = [bsd_int(ctrl[pos+i:pos+i+8]) for i in (0, 8, 16)]
        out.write(struct.pack("<qqq", x, y, z))
        out.write(diff[diff_pos:diff_pos+x])
        out.write(extra[extra_pos:extra_pos+y])
        diff_pos += x
        extra_pos += y
    if diff_pos != len(diff) or extra_pos != len(extra):
        raise SystemExit("Unused binary delta data")
manifest = {
    "schemaVersion": 1,
    "sourceCommit": commit,
    "sourcePatchSha256": sha((root / "patches/sm64coopdx.patch").read_bytes()),
    "upstreamUrl": "https://github.com/coop-deluxe/sm64coopdx/releases/download/v1.5.1/sm64coopdx_Windows.zip",
    "upstreamSha256": archive_sha,
    "originalExeSha256": sha(base),
    "targetExeSha256": sha(target),
    "deltaSha256": sha(patch_path.read_bytes()),
    "romIncluded": False,
}
(args.output / "native-manifest.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
print(f"Verified ROM-free delta: {patch_path.stat().st_size / 1024**2:.2f} MiB", flush=True)
