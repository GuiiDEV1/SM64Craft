"""Assert real native triggers, saved progression, and matching Minecraft regions."""
import json
from pathlib import Path
import re

root = Path(__file__).resolve().parent.parent / 'dist/multiplayer-probe'
report = {'scope': 'native passage round trips and one-star door progression; scripted positioning, not a full playthrough', 'roles': {}}
rows = [json.loads(line) for line in (root / 'passages-observations.jsonl').read_text().splitlines() if line.strip()]
for role in ('Host', 'Guest'):
    first = (root / role / 'passages-native.log').read_text(errors='replace')
    repeat = (root / role / 'passages-return-native.log').read_text(errors='replace')
    assert re.search(r'DOOR case=door-before stars=0 .*lockedDialog=true .*unlock=false', first), (role, 'door was not locked before star')
    assert re.search(r'DOOR case=door-after stars=1 .*lockedDialog=false .*unlock=true', first), (role, 'one-star door did not unlock')
    assert re.search(r'STATE case=door-after age=\d+ level=6 area=1 act=0 stars=1 .*flags=2049', first, re.S), (role, 'native star-door animation did not set WF unlock flag')
    assert re.search(r'LOAD case=DDD stars=1 flags=1', repeat), (role, 'star progress did not survive restart')
    assert re.search(r'COMPLETE stars=1 flags=1', repeat), (role, 'star progress missing at test end')
    for case, level in [('DDD', 23), ('WDW', 11)]:
        for destination in (1, 2):
            assert f'INSTANT case={case} destination={destination}' in repeat, (role, case, 'missing native warp', destination)
        for area, interval in [(2, (210, 420)), (1, (510, 720))]:
            states = re.findall(rf'STATE case={case} age=(\d+) level={level} area={area} stars=1 flags=1 health=(\d+) players=2', repeat)
            stable = [(int(age), int(health)) for age, health in states if interval[0] <= int(age) <= interval[1]]
            assert len(stable) >= 5 and all(health > 0 for _, health in stable), (role, case, area, 'unstable passage')
    samples = [row[role] for row in rows if role in row and abs(row[role]['time'] / 1000 - row['time']) < 5]
    worlds = {s['nativeWorld'] for s in samples if s.get('world') and s.get('linked') and s.get('players') == 2}
    assert {369, 370, 177, 178}.issubset(worlds), (role, 'missing Minecraft region', worlds)
    report['roles'][role] = {'zeroStarDoorLocked': True, 'oneStarDoorUnlockAnimation': True,
        'oneStarProgressSurvivedRestart': True, 'doorUnlockBitPersisted': False,
        'DDDForwardAndReturn': True, 'WDWForwardAndReturn': True, 'minecraftRegions': sorted(worlds)}
assert 'EXISTING_STAR params=83886080' in (root / 'Host/passages-native.log').read_text(errors='replace'), 'must use the existing Bob-omb Battlefield star'
target = root / 'passages-validation-report.json'
target.write_text(json.dumps(report, indent=2))
print(json.dumps(report, indent=2))
