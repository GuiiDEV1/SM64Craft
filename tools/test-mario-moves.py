"""Compile and exercise MarioCraft's actual jump-edge and move-selection policies."""
from pathlib import Path
import re
import subprocess
import tempfile

root = Path(__file__).resolve().parent.parent
source = (root / "sm64coopdx/src/pc/mariocraft/mariocraft.c").read_text(encoding="utf-8")


def extract(pattern: str) -> str:
    match = re.search(pattern, source, re.M)
    if not match:
        raise SystemExit(f"Missing actual movement policy: {pattern}")
    start = match.start()
    brace = source.find("{", match.start())
    end, depth = brace + 1, 1
    while depth:
        depth += (source[end] == "{") - (source[end] == "}")
        end += 1
    return source[start:end]


enum = re.search(r"enum SteveMarioJump\s*\{[^}]+\};", source, re.S)
if not enum:
    raise SystemExit("Missing actual SteveMarioJump enum")
functions = [
    extract(r"static bool steve_jump_press_edge\s*\([^)]*\)\s*\{"),
    extract(r"static enum SteveMarioJump steve_choose_jump\s*\([^)]*\)\s*\{"),
]
test = r'''
int main(void) {
    bool wasDown = false;
    uint32_t lastSeq = 0;
    /* A press and release between SM64 frames remains visible exactly once. */
    assert(steve_jump_press_edge(false, 7, true, &wasDown, &lastSeq));
    assert(!steve_jump_press_edge(false, 7, true, &wasDown, &lastSeq));
    /* Classic mode still detects a held Space edge, not every frame it remains held. */
    assert(steve_jump_press_edge(true, 0, false, &wasDown, &lastSeq));
    assert(!steve_jump_press_edge(true, 0, false, &wasDown, &lastSeq));
    assert(!steve_jump_press_edge(false, 0, false, &wasDown, &lastSeq));
    assert(steve_jump_press_edge(true, 0, false, &wasDown, &lastSeq));
    /* Long jump / backflip take priority over the running jump chain. */
    assert(steve_choose_jump(true, 0.30f, true, 2) == STEVE_JUMP_LONG);
    assert(steve_choose_jump(true, 0.01f, true, 1) == STEVE_JUMP_BACKFLIP);
    /* A one-tick landing-and-rejump needs no intermediate grounded sample. */
    assert(steve_choose_jump(false, 0.12f, true, 1) == STEVE_JUMP_DOUBLE);
    assert(steve_choose_jump(false, 0.22f, true, 2) == STEVE_JUMP_TRIPLE);
    assert(steve_choose_jump(false, 0.10f, false, 1) == STEVE_JUMP_NONE);
    assert(steve_choose_jump(false, 0.10f, true, 0) == STEVE_JUMP_NONE);
    puts("PASS: 13 Mario movement input and selection assertions");
}
'''

with tempfile.TemporaryDirectory(prefix="mariocraft-moves-") as directory:
    c_file = Path(directory) / "moves.c"
    exe = Path(directory) / "moves.exe"
    c_file.write_text(
        "#include <assert.h>\n#include <stdbool.h>\n#include <stdint.h>\n#include <stdio.h>\n"
        + enum.group(0)
        + "\n"
        + "\n".join(functions)
        + "\n"
        + test,
        encoding="utf-8",
    )
    subprocess.run(["gcc", "-std=c11", "-Wall", "-Wextra", "-Werror", str(c_file), "-o", str(exe)], check=True)
    subprocess.run([str(exe)], check=True)
