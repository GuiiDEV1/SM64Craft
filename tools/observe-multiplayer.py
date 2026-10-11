"""Record development client state without controlling desktop input."""
import argparse
import json
from pathlib import Path
import time

p = argparse.ArgumentParser()
p.add_argument('--seconds', type=int, default=900)
p.add_argument('--output', type=Path, required=True)
p.add_argument('--stop-file', type=Path)
a = p.parse_args()
root = Path(__file__).resolve().parent.parent / 'dist/multiplayer-probe'
deadline = time.monotonic() + a.seconds
with a.output.open('w', encoding='utf-8') as out:
    while time.monotonic() < deadline:
        if a.stop_file and a.stop_file.exists():
            break
        row = {'time': time.time()}
        for role in ('Host', 'Guest'):
            try:
                row[role] = json.loads((root / role / 'probe/state.json').read_text())
            except (OSError, ValueError):
                pass
        out.write(json.dumps(row) + '\n')
        out.flush()
        time.sleep(1)
print('Recorded', a.output)
