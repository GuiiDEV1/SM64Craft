"""Validate a user-provided Super Mario 64 USA ROM and normalize its byte order."""
from __future__ import annotations

import hashlib
from pathlib import Path
import sys

USA_SHA1 = "9bef1128717f958171a4afac3ed78ee2bb4e86ce"
OTHER = {
    "8a20a5c83d6ceb0f0506cfc9fa20d8f438cafe51": "the Japanese version",
    "4ac5721683d0e0b6bbb561b58a71740845dceea9": "the European version",
    "3f319ae697533a255a1003d09202379d78d5a2e0": "the Shindou (Japanese rumble) version",
}


def canonical_bytes(data: bytes) -> bytes | None:
    if data[:4] == b"\x80\x37\x12\x40":
        return data
    if data[:4] == b"\x37\x80\x40\x12" and len(data) % 2 == 0:
        result = bytearray(data)
        result[0::2], result[1::2] = data[1::2], data[0::2]
        return bytes(result)
    if data[:4] == b"\x40\x12\x37\x80" and len(data) % 4 == 0:
        result = bytearray(data)
        result[0::4], result[1::4], result[2::4], result[3::4] = data[3::4], data[2::4], data[1::4], data[0::4]
        return bytes(result)
    return None


def main() -> int:
    if len(sys.argv) < 2:
        print("Usage: prepare-rom.py <instance-rom-folder> [legacy-source-folder]")
        return 2
    target = Path(sys.argv[1]).resolve()
    source_dirs = [target]
    if len(sys.argv) > 2:
        legacy = Path(sys.argv[2]).resolve()
        if legacy != target:
            source_dirs.append(legacy)
    target.mkdir(parents=True, exist_ok=True)
    candidates: list[Path] = []
    for folder in source_dirs:
        if folder.is_dir():
            candidates.extend(p for p in folder.iterdir() if p.is_file() and p.suffix.lower() in {".z64", ".n64", ".v64"})
    candidates.sort(key=lambda p: (p.name.lower() != "baserom.us.z64", source_dirs.index(p.parent), p.name.lower()))
    if not candidates:
        print("No .z64, .n64 or .v64 ROM found in the sm64craft folder.")
        return 1
    for path in candidates:
        data = path.read_bytes()
        z64 = canonical_bytes(data)
        if z64 is None:
            print(f"  {path.name}: not a supported Nintendo 64 ROM format")
            continue
        digest = hashlib.sha1(z64).hexdigest()
        if digest != USA_SHA1:
            print(f"  {path.name}: {OTHER.get(digest, 'not the expected unmodified USA ROM')}")
            continue
        canonical = target / "baserom.us.z64"
        if path == canonical:
            print(f"Using verified USA ROM: {path}")
            return 0
        if canonical.exists():
            existing = canonical_bytes(canonical.read_bytes())
            if existing is None or hashlib.sha1(existing).hexdigest() != USA_SHA1:
                print(f"Refusing to overwrite the existing file {canonical}; rename it, then try again.")
                return 1
            if existing != z64:
                print(f"A different valid USA ROM is already set up at {canonical}; leaving it unchanged.")
                return 0
        else:
            canonical.write_bytes(z64)
        print(f"Verified {path.name}; ready at {canonical}")
        return 0
    print("No valid unmodified Super Mario 64 USA ROM was found.")
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
