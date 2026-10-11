-- name: MarioCraft Multiplayer Validation
-- description: Passage round trips and saved one-star progress, isolated developer fixture.
local tick, current, age, entered, returned = 0, 0, 0, false, false
local cases = {{'DDD', LEVEL_DDD}, {'WDW', LEVEL_WDW}}
local function position(m, x, y, z)
    m.pos.x, m.pos.y, m.pos.z = x, y, z
    m.vel.x, m.vel.y, m.vel.z = 0, 0, 0
    m.floor = collision_find_floor(x, y + 100, z)
    print(string.format('[PASSAGES-RETURN] APPROACH case=%s return=%s floor=%d', cases[current][1], tostring(entered), m.floor and m.floor.type or -1))
end
hook_event(HOOK_ON_INSTANT_WARP, function(area, id, displacement)
    print(string.format('[PASSAGES-RETURN] INSTANT case=%s destination=%d id=%d', cases[current][1], area, id))
end)
hook_event(HOOK_UPDATE, function()
    if network_player_connected_count() < 2 then return end
    tick = tick + 1
    if network_is_server() then gGlobalSyncTable.returnCase = math.floor((tick - 600) / 750) + 1 end
    local index = gGlobalSyncTable.returnCase or 0
    if index < 1 then return end
    local m, np = gMarioStates[0], gNetworkPlayers[0]
    if index > #cases then
        if current ~= -1 then
            current = -1; warp_to_start_level()
            print(string.format('[PASSAGES-RETURN] COMPLETE stars=%d flags=%d', m.numStars, save_file_get_flags()))
        end
        return
    end
    local c = cases[index]
    if current ~= index then
        current, age, entered, returned = index, 0, false, false
        print(string.format('[PASSAGES-RETURN] LOAD case=%s stars=%d flags=%d result=%s', c[1], m.numStars, save_file_get_flags(), tostring(warp_to_level(c[2], 1, 1))))
    end
    age = age + 1
    if np.currLevelNum == c[2] and age >= 150 and not entered and np.currAreaIndex == 1 then
        if index == 1 then position(m, 4200, -500, 0) else position(m, 352, -1490, -3300) end
        entered = true
    end
    if np.currLevelNum == c[2] and age >= 450 and not returned and np.currAreaIndex == 2 then
        if index == 1 then position(m, -4200, -500, 0) else position(m, 416, -1490, -3300) end
        returned = true
    end
    if age % 30 == 0 then
        print(string.format('[PASSAGES-RETURN] STATE case=%s age=%d level=%d area=%d stars=%d flags=%d health=%d players=%d x=%.2f y=%.2f z=%.2f',
            c[1], age, np.currLevelNum, np.currAreaIndex, m.numStars, save_file_get_flags(), m.health, network_player_connected_count(), m.pos.x, m.pos.y, m.pos.z))
    end
end)
