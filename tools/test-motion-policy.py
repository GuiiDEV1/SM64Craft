"""Compile the actual C transition guards in isolation (no ROM, renderer or saves)."""
from pathlib import Path
import re
import subprocess
import tempfile

root = Path(__file__).resolve().parent.parent
source = (root / "sm64coopdx/src/pc/mariocraft/mariocraft.c").read_text(encoding="utf-8")
constants = (root / "sm64coopdx/include/sm64.h").read_text(encoding="utf-8")
definitions = "\n".join(re.findall(r"^#define ACT_\w+\s+0x[0-9a-fA-F]+", constants, re.M))
definitions += "\n" + "\n".join(re.findall(r"^#define ACT_GROUP_\w+\s+/\*.*\*/.*$", constants, re.M))
functions = []
for name in ("area_geometry_ready", "sm64_owns_motion", "is_course_exit", "mariocraft_blocks_painting_warp", "mariocraft_blocks_pole_grab"):
    match = re.search(r"(?:static\s+)?bool\s+" + name + r"\s*\([^)]*\)\s*\{", source)
    if not match:
        raise SystemExit(f"Missing actual guard function: {name}")
    end, depth = match.end(), 1
    while depth:
        depth += (source[end] == "{") - (source[end] == "}")
        end += 1
    functions.append(source[match.start():end])
header = """
#include <assert.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
typedef uint32_t u32;
static uint32_t sPendingGeometryWorld = UINT32_MAX, sPendingSurfaceGeneration = UINT32_MAX;
struct MarioState { int playerIndex; };
struct Object { int unused; };
static void *gMcShm;
static bool sSteveActive, sRehoming, sPaintingExitGuard;
static struct Object *sReleasedPole;
static uint32_t gGlobalTimer, sPoleReleaseTick;
"""
tests = """
int main(void) {
    assert(!area_geometry_ready(257, 1, false));
    assert(!area_geometry_ready(257, 1, true));
    assert(area_geometry_ready(257, 1, true));
    assert(!area_geometry_ready(145, 1, true)); // new level still has the old surface pool
    assert(!area_geometry_ready(145, 2, true)); // loader has now replaced it
    assert(area_geometry_ready(145, 2, true));
    assert(!area_geometry_ready(145, 3, false));
    assert(!area_geometry_ready(145, 3, true)); // reloading the same area must also resend geometry
    assert(area_geometry_ready(145, 3, true));
    assert(sm64_owns_motion(ACT_EXIT_AIRBORNE));
    assert(sm64_owns_motion(ACT_DEATH_EXIT_LAND));
    assert(sm64_owns_motion(ACT_STAR_DANCE_EXIT));
    assert(!sm64_owns_motion(ACT_IDLE));
    assert(!sm64_owns_motion(ACT_FREEFALL));
    assert(is_course_exit(ACT_EXIT_AIRBORNE));
    assert(is_course_exit(ACT_FALLING_DEATH_EXIT));
    assert(is_course_exit(ACT_EXIT_LAND_SAVE_DIALOG));
    assert(!is_course_exit(ACT_IDLE));
    assert(!is_course_exit(ACT_STAR_DANCE_NO_EXIT));
    gMcShm = (void *)1;
    sPaintingExitGuard = true;
    assert(!mariocraft_blocks_painting_warp()); // native fallback still works without Steve
    sSteveActive = true;
    assert(mariocraft_blocks_painting_warp());
    sPaintingExitGuard = false;
    assert(!mariocraft_blocks_painting_warp()); // deliberate entries still work
    sSteveActive = false; sRehoming = true;
    assert(mariocraft_blocks_painting_warp());
    gMcShm = NULL;
    assert(!mariocraft_blocks_painting_warp());
    struct Object tree, other;
    struct MarioState local = {0}, remote = {1};
    gMcShm = (void *)1; sRehoming = false; sReleasedPole = &tree;
    sPoleReleaseTick = 100; gGlobalTimer = 129;
    assert(mariocraft_blocks_pole_grab(&local, &tree));
    assert(!mariocraft_blocks_pole_grab(&remote, &tree));
    assert(!mariocraft_blocks_pole_grab(&local, &other));
    gGlobalTimer = 130;
    assert(!mariocraft_blocks_pole_grab(&local, &tree));
    sRehoming = true;
    assert(mariocraft_blocks_pole_grab(&local, &tree));
    sRehoming = false; sPoleReleaseTick = UINT32_MAX - 1; gGlobalTimer = 1;
    assert(mariocraft_blocks_pole_grab(&local, &tree));
    gMcShm = NULL;
    assert(!mariocraft_blocks_pole_grab(&local, &tree));
    puts("PASS: 31 native geometry/motion/painting/pole policy assertions");
}
"""
with tempfile.TemporaryDirectory(prefix="mariocraft-motion-") as temporary:
    test = Path(temporary) / "motion.c"
    executable = Path(temporary) / "motion.exe"
    test.write_text(header + definitions + "\n" + "\n".join(functions) + tests, encoding="utf-8")
    subprocess.run(["gcc", "-std=c11", "-Wall", "-Wextra", "-Werror", str(test), "-o", str(executable)], check=True)
    subprocess.run([str(executable)], check=True)
