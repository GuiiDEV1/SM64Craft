"""Check Java and native offsets agree for the Minecraft <-> SM64 shared state."""
from pathlib import Path
import re

root = Path(__file__).resolve().parent.parent
c = (root / "sm64coopdx/src/pc/mariocraft/mariocraft.c").read_text(encoding="utf-8")
java = (root / "SkyCraft/fabric/src/main/java/dev/skycraft/link/Proto.java").read_text(encoding="utf-8")

expected = {
    "MS_HOST_VIEW_FLAGS": 0x4C,
    "MS_EYE_X": 0x50,
    "MS_TICK_QPC": 0x68,
    "MS_PREV_X": 0x70,
    "MS_EYE_HEIGHT_O": 0xA0,
    "MS_TICK_MS": 0xB8,
    "MS_JUMP_PRESS_SEQ": 0xBC,
    "MS_CAMERA_MODE": 0xC0,
    "MS_CAMERA_DISTANCE": 0xC4,
}
for name, offset in expected.items():
    match = re.search(r"public static final long " + name + r"\s*=\s*0x([0-9A-Fa-f]+)", java)
    if not match or int(match.group(1), 16) != offset:
        raise SystemExit(f"Java offset mismatch for {name}: expected 0x{offset:X}")

fields = re.search(r"struct McState\s*\{(.*?)\};", c, re.S)
if not fields:
    raise SystemExit("Native McState definition is missing")
native = re.sub(r"//.*", "", fields.group(1))
offset = 0
widths = {
    "uint32_t": 4, "int64_t": 8, "uint64_t": 8, "double": 8, "float": 4,
}
seen = {}
for type_name, names in re.findall(r"\b(uint32_t|int64_t|uint64_t|double|float)\s+([^;]+);", native):
    for name in names.split(","):
        field = name.strip().split()[0]
        seen[field] = offset
        offset += widths[type_name]
if offset != 0xC8:
    raise SystemExit(f"Native McState size is 0x{offset:X}, expected 0xC8")
c_offsets = {
	"pad4C": 0x4C, "eyeX": 0x50, "tickQpc": 0x68, "prevX": 0x70,
    "tickEyeO": 0xA0, "tickMs": 0xB8, "jumpPressSeq": 0xBC,
    "cameraMode": 0xC0, "cameraDistance": 0xC4,
}
for field, expected_offset in c_offsets.items():
    if seen.get(field) != expected_offset:
        raise SystemExit(f"Native offset mismatch for {field}: got {seen.get(field)}, expected 0x{expected_offset:X}")
print("PASS: 9 shared-state offsets match; McState remains 0xC8 bytes")
