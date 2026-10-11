-- name: MarioCraft Multiplayer Validation
-- description: Retry areas without entry warp nodes; not a completed playthrough.

local tick, current, age, entered = 0, 0, 0, false
local cases = {
    {100, 'DDD-submarine', LEVEL_DDD, 2},
    {101, 'WDW-town', LEVEL_WDW, 2},
}
hook_event(HOOK_UPDATE, function()
    if network_player_connected_count() < 2 then return end
    tick = tick + 1
    if network_is_server() then gGlobalSyncTable.retryCase = math.floor((tick - 900) / 600) + 1 end
    local index = gGlobalSyncTable.retryCase or 0
    if index < 1 then return end
    if index > #cases then
        if current ~= -1 then current = -1; warp_to_start_level(); print('[AREA-RETRY] COMPLETE') end
        return
    end
    local c = cases[index]
    if current ~= index then
        current, age, entered = index, 0, false
        local ok = warp_to_level(c[3], 1, 1)
        print('[AREA-RETRY] base-load label=' .. c[2] .. ' result=' .. tostring(ok))
    end
    age = age + 1
    local np = gNetworkPlayers[0]
    if not entered and age >= 90 and np.currLevelNum == c[3] and np.currAreaIndex == 1 then
        smlua_level_util_change_area(c[4])
        entered = true
        print(string.format('[AREA-RETRY] ENTER case=%d/119 label=%s requestedLevel=%d requestedArea=%d requestedAct=1 result=true', c[1], c[2], c[3], c[4]))
    end
    if age % 30 == 0 then
        print(string.format('[AREA-RETRY] STATE case=%d label=%s level=%d area=%d act=%d players=%d', c[1], c[2], np.currLevelNum, np.currAreaIndex, np.currActNum, network_player_connected_count()))
    end
end)
