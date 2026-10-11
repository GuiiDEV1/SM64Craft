"""Compile the production world-ID helper and check every supported main-course act."""
from pathlib import Path
import re
import subprocess
import tempfile

root = Path(__file__).resolve().parent.parent
source = (root / 'sm64coopdx/src/pc/mariocraft/mariocraft_internal.h').read_text()
match = re.search(r'static inline uint32_t mc_world_id\([^)]*\)\s*\{', source)
end, depth = match.end(), 1
while depth:
    depth += (source[end] == '{') - (source[end] == '}')
    end += 1
helper = source[match.start():end]
code = '#include <stdint.h>\n#include <assert.h>\n' + helper + r'''
int main(void) {
    for (int level = 1; level <= 36; level++) {
        for (int area = 1; area <= 4; area++) {
            unsigned legacy = level * 16 + area;
            assert(mc_world_id(level, area, 1, 1) == legacy);
            assert(mc_world_id(level, area, 0, 6) == legacy);
            assert(mc_world_id(level, area, 16, 6) == legacy);
            assert(mc_world_id(level, area, 1, 99) == legacy);
            for (int act = 1; act <= 6; act++) {
                unsigned id = mc_world_id(level, area, 1, act);
                assert(id < 8192);
                assert(10000.0 + id * 256.0 < 30000000.0);
                for (int other = 1; other <= 6; other++) {
                    if (act != other) assert(id != mc_world_id(level, area, 1, other));
                }
            }
        }
    }
    return 0;
}
'''
with tempfile.TemporaryDirectory(prefix='mariocraft-act-test-') as directory:
    c = Path(directory) / 'test.c'
    exe = Path(directory) / 'test.exe'
    c.write_text(code)
    subprocess.run(['gcc', str(c), '-o', str(exe)], check=True)
    subprocess.run([str(exe)], check=True)
print('PASS: all 6 acts isolated; 144 level/area combinations preserve legacy and coordinate limits')
