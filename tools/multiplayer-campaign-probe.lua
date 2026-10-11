-- name: MarioCraft Multiplayer Validation
-- description: Developer loading/mission regression, not a completed playthrough.

local cases = {}
local function add(label, level, area, hostAct, guestAct)
    cases[#cases + 1] = { label, level, area, hostAct, guestAct }
end
add('different-BOB-acts', LEVEL_BOB, 1, 1, 2)
add('same-BOB-act', LEVEL_BOB, 1, 1, 1)
add('different-WF-acts', LEVEL_WF, 1, 1, 6)
add('different-JRB-acts', LEVEL_JRB, 1, 1, 6)
local courses = {
    {'BOB', LEVEL_BOB}, {'WF', LEVEL_WF}, {'JRB', LEVEL_JRB},
    {'CCM', LEVEL_CCM}, {'BBH', LEVEL_BBH}, {'HMC', LEVEL_HMC},
    {'LLL', LEVEL_LLL}, {'SSL', LEVEL_SSL}, {'DDD', LEVEL_DDD},
    {'SL', LEVEL_SL}, {'WDW', LEVEL_WDW}, {'THI', LEVEL_THI},
    {'TTC', LEVEL_TTC}, {'RR', LEVEL_RR}, {'TTM', LEVEL_TTM},
}
for _, course in ipairs(courses) do
    for act = 1, 6 do add(course[1] .. '-act-' .. act, course[2], 1, act, act) end
end
local extra = {
    {'CCM-slide', LEVEL_CCM, 2}, {'HMC-cavern', LEVEL_HMC, 1},
    {'LLL-volcano', LEVEL_LLL, 2}, {'SSL-pyramid', LEVEL_SSL, 2},
    {'JRB-cave', LEVEL_JRB, 2}, {'DDD-submarine', LEVEL_DDD, 2},
    {'WDW-town', LEVEL_WDW, 2}, {'THI-tiny', LEVEL_THI, 2},
    {'THI-cave', LEVEL_THI, 3}, {'TTM-slide', LEVEL_TTM, 2},
    {'BITDW', LEVEL_BITDW, 1}, {'BITFS', LEVEL_BITFS, 1}, {'BITS', LEVEL_BITS, 1},
    {'BOWSER-1-arena', LEVEL_BOWSER_1, 1}, {'BOWSER-2-arena', LEVEL_BOWSER_2, 1},
    {'BOWSER-3-arena', LEVEL_BOWSER_3, 1}, {'PSS', LEVEL_PSS, 1},
    {'COTMC', LEVEL_COTMC, 1}, {'TOTWC', LEVEL_TOTWC, 1},
    {'VCUTM', LEVEL_VCUTM, 1}, {'SA', LEVEL_SA, 1}, {'WMOTR', LEVEL_WMOTR, 1},
    {'CASTLE-inside', LEVEL_CASTLE, 1}, {'CASTLE-courtyard', LEVEL_CASTLE_COURTYARD, 1},
    {'CASTLE-grounds', LEVEL_CASTLE_GROUNDS, 1},
}
for _, c in ipairs(extra) do
    local act = string.sub(c[1], 1, 6) == 'CASTLE' and 0 or 1
    add(c[1], c[2], c[3], act, act)
end

local tick, current = 0, 0
hook_event(HOOK_UPDATE, function()
    if network_player_connected_count() < 2 then return end
    if network_is_server() then
        tick = tick + 1
        gGlobalSyncTable.campaignCase = math.floor((tick - 900) / 180) + 1
    else tick = tick + 1 end
    local index = gGlobalSyncTable.campaignCase or 0
    if index < 1 then return end
    if index > #cases then
        if current ~= -1 then
            current = -1
            warp_to_start_level()
            print('[CAMPAIGN-PROBE] COMPLETE loading-cases=' .. #cases)
        end
        return
    end
    local c = cases[index]
    if index ~= current then
        current = index
        local act = network_is_server() and c[4] or c[5]
        local result = warp_to_level(c[2], c[3], act)
        print(string.format('[CAMPAIGN-PROBE] ENTER case=%d/%d label=%s requestedLevel=%d requestedArea=%d requestedAct=%d result=%s',
            index, #cases, c[1], c[2], c[3], act, tostring(result)))
    end
    if tick % 30 == 0 then
        local np, m = gNetworkPlayers[0], gMarioStates[0]
        local boss = obj_get_first_with_behavior_id(id_bhvBowser)
        print(string.format('[CAMPAIGN-PROBE] STATE case=%d label=%s level=%d area=%d act=%d stars=%d players=%d action=%d health=%d bowser=%s',
            index, c[1], np.currLevelNum, np.currAreaIndex, np.currActNum,
            m.numStars, network_player_connected_count(), m.action, m.health, tostring(boss ~= nil)))
    end
end)
