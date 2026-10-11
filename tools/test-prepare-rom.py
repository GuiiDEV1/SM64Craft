"""Verify ROM byte-order normalization using the user's local USA dump in a temp folder."""
from pathlib import Path
import subprocess
import sys
import tempfile

root = Path(__file__).resolve().parent.parent
source = root / "baserom.us.z64"
if not source.is_file():
    raise SystemExit("Put your own baserom.us.z64 in the project for this local-only test")
rom = source.read_bytes()
if rom[:4] != b"\x80\x37\x12\x40":
    raise SystemExit("Local ROM is not in canonical .z64 byte order")

with tempfile.TemporaryDirectory(prefix="mariocraft-rom-test-") as directory:
    base = Path(directory)
    for suffix, data in (
        ("v64", bytes(v for pair in zip(rom[1::2], rom[0::2]) for v in pair)),
        ("n64", bytes(v for quad in zip(rom[3::4], rom[2::4], rom[1::4], rom[0::4]) for v in quad)),
    ):
        folder = base / suffix
        folder.mkdir()
        original = folder / f"my USA dump.{suffix}"
        original.write_bytes(data)
        result = subprocess.run([sys.executable, str(root / "tools/prepare-rom.py"), str(folder)], check=True, capture_output=True, text=True)
        canonical = folder / "baserom.us.z64"
        assert canonical.read_bytes() == rom, f"{suffix} normalization changed ROM bytes"
        assert original.read_bytes() == data, f"{suffix} source was modified"
        assert "Verified" in result.stdout

    guarded = base / "preserve-invalid-name"
    guarded.mkdir()
    bad_target = guarded / "baserom.us.z64"
    bad_target.write_bytes(b"user file stays untouched")
    (guarded / "good.z64").write_bytes(rom)
    result = subprocess.run([sys.executable, str(root / "tools/prepare-rom.py"), str(guarded)], capture_output=True, text=True)
    assert result.returncode == 1 and "Refusing to overwrite" in result.stdout
    assert bad_target.read_bytes() == b"user file stays untouched"

print("PASS: .v64/.n64 normalization and safe refusal to overwrite an invalid named file")
