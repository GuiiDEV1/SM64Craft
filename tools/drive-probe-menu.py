"""Send menu events through the explicit development probe; never sends desktop input."""
import argparse
import json
from pathlib import Path
import time

p = argparse.ArgumentParser()
p.add_argument('role', choices=['Host', 'Guest', 'Guest2'])
p.add_argument('--click', nargs=2, type=int)
p.add_argument('--text')
p.add_argument('--key', type=int, help='SM64 Windows Set-1 scancode')
a = p.parse_args()
root = Path(__file__).resolve().parent.parent / 'dist/multiplayer-probe' / a.role / 'probe'
deadline = time.monotonic() + 45
while time.monotonic() < deadline:
    try:
        state = json.loads((root / 'state.json').read_text())
        if state.get('linked') and state.get('screen') == 'MarioCraftMenuScreen' and abs(time.time() * 1000 - state['time']) < 5000:
            break
    except (OSError, ValueError):
        pass
    time.sleep(0.5)
else:
    raise SystemExit('Development SM64 menu is not ready; no input sent.')
def send(events, **extra):
    data = {'action': 'nativeInput', 'seq': time.time_ns(), 'events': events, **extra}
    temporary = root / 'command.tmp'
    temporary.write_text(json.dumps(data), encoding='utf-8')
    temporary.replace(root / 'command.json')
    time.sleep(0.8)
if a.click:
    x, y = a.click
    send([], x=x, y=y)
    send([[3, 0, 1, 0], [3, 0, 0, 0]], x=x, y=y)
if a.text is not None:
    send([[5, ord(character), 0, 0] for character in a.text])
if a.key is not None:
    send([[1, a.key, 0, 0], [2, a.key, 0, 0]])
