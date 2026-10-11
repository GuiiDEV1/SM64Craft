"""Report observed loading coverage without calling it a completed campaign."""
import json
from pathlib import Path
import re

root = Path(__file__).resolve().parent.parent / 'dist/multiplayer-probe'
enter = re.compile(r'ENTER case=(\d+)/(\d+) label=(\S+) requestedLevel=(\d+) requestedArea=(\d+) requestedAct=(\d+) result=(\S+)')
state = re.compile(r'STATE case=(\d+) label=(\S+) level=(\d+) area=(\d+) act=(\d+)')
rows = []
for observations in root.glob('missions-fixed*observations.jsonl'):
    for line in observations.read_text().splitlines():
        try:
            rows.append(json.loads(line))
        except ValueError:
            pass
report = {'scope': 'loading and mission integration, not star objectives or defeated bosses', 'roles': {}}
for role in ('Host', 'Guest'):
    campaign_log = root / role / 'campaign-native.log'
    log = (campaign_log if campaign_log.exists() else root / role / 'native.log').read_text(errors='replace')
    original_rejections = [int(m[1]) for m in enter.finditer(log) if m[7] != 'true']
    retry_log = root / role / 'area-retry-native.log'
    if retry_log.exists():
        log += '\n' + retry_log.read_text(errors='replace')
    requested = {int(m[1]): {'label': m[3], 'level': int(m[4]), 'area': int(m[5]), 'act': int(m[6]), 'result': m[7]} for m in enter.finditer(log)}
    actual = {}
    for m in state.finditer(log):
        actual.setdefault(int(m[1]), set()).add((int(m[3]), int(m[4]), int(m[5])))
    matched = []
    missing = []
    missing_regions = []
    samples = [r[role] for r in rows if role in r and abs(r[role]['time'] / 1000 - r['time']) < 5]
    observed_worlds = {s['nativeWorld'] for s in samples if s.get('world') and s.get('linked')}
    # Main courses are precisely the first 94 loading cases (4 comparisons + 90 acts),
    # plus ten extra interior areas; HMC is also a main-course interior repeat.
    main_levels = {9, 24, 12, 5, 4, 7, 22, 8, 23, 10, 11, 13, 14, 15, 36}
    for index, case in requested.items():
        # Castle has no star-selection act, even when the generic warp helper is passed 1.
        actual_act = 0 if case['level'] in {6, 16, 26} else case['act']
        position = (case['level'], case['area'], actual_act)
        if case['result'] == 'true' and position in actual.get(index, set()):
            matched.append(index)
        else:
            missing.append({'case': index, **case})
        world = case['level'] * 16 + case['area']
        if case['level'] in main_levels and 2 <= case['act'] <= 6:
            world += (case['act'] - 1) * 1024
        if world not in observed_worlds:
            missing_regions.append({'case': index, 'expectedWorld': world, **case})
    report['roles'][role] = {
        'requested': len(requested), 'nativeMatched': len(matched), 'nativeMissing': missing,
        'minecraftMissingRegions': missing_regions, 'uniqueMinecraftRegions': len(observed_worlds),
        'minimumY': min((s.get('y', 0) for s in samples), default=None),
        'completeMarker': 'COMPLETE loading-cases=119' in log,
        'originalFixtureRejections': original_rejections,
    }
target = root / 'campaign-loading-report.json'
target.write_text(json.dumps(report, indent=2))
print(json.dumps(report, indent=2))
