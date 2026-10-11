"""Read only isolated test channels, or request their native process to close normally."""
import argparse
import json
import mmap
import struct
from pathlib import Path

p = argparse.ArgumentParser()
p.add_argument('role')
p.add_argument('--close', action='store_true')
p.add_argument('--image', type=Path)
a = p.parse_args()
name = 'Local\\MarioCraft_probe_' + a.role
with mmap.mmap(-1, 0x300, tagname=name) as game:
    assert struct.unpack_from('<I', game)[0] == 0x43594b53
    print(json.dumps(dict(role=a.role, nativeSeq=struct.unpack_from('<I', game, 0x130)[0],
                          minecraftAck=struct.unpack_from('<I', game, 0x230)[0],
                          world=struct.unpack_from('<I', game, 0x108)[0])))
input_offset = 64 + 1280 * 720 * 4
with mmap.mmap(-1, input_offset + 64 + 256 * 16, tagname=name + '_frame') as frame:
    seq, magic, version, width, height, bpp = struct.unpack_from('<6I', frame)
    assert magic == 0x3146434d, 'No native frame channel'
    print(json.dumps(dict(role=a.role, width=width, height=height, frames=struct.unpack_from('<Q', frame, 40)[0])))
    if a.close:
        struct.pack_into('<I', frame, input_offset + 32, 1)
    if a.image:
        from PIL import Image
        Image.frombytes('RGBA', (width, height), frame[64:64 + width * height * 4]).save(a.image)
