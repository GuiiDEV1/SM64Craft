-- name: MarioCraft Multiplayer Validation
-- description: Isolated passage triggers and one-star progression; never packaged.
local tick, current, age, attempted = 0, 0, 0, false
local cases = {
    {'door-before', LEVEL_CASTLE}, {'real-star', LEVEL_BOB},
    {'door-after', LEVEL_CASTLE}, {'DDD-passage', LEVEL_DDD},
    {'WDW-passage', LEVEL_WDW},
}
local function position(m, x, y, z)
    m.pos.x, m.pos.y, m.pos.z = x, y, z
    m.vel.x, m.vel.y, m.vel.z = 0, 0, 0
    m.floor = collision_find_floor(x, y + 100, z)
end
local function one_star_door()
    local o = obj_get_first_with_behavior_id(id_bhvDoor)
    while o ~= nil do
        if ((o.oBehParams >> 24) & 255) == 1 then return o end
        o = obj_get_next_with_same_behavior_id(o)
    end
end
hook_event(HOOK_ON_INSTANT_WARP, function(area, id, displacement)
    print(string.format('[PASSAGES] INSTANT case=%s destination=%d id=%d dx=%d dy=%d dz=%d',
        cases[current][1], area, id, displacement.x, displacement.y, displacement.z))
end)
hook_event(HOOK_UPDATE, function()
    if network_player_connected_count() < 2 then return end
    tick = tick + 1
    if network_is_server() then
        gServerSettings.stayInLevelAfterStar = 2
        gGlobalSyncTable.passageCase = math.floor((tick - 600) / 600) + 1
    end
    local index = gGlobalSyncTable.passageCase or 0
    if index < 1 then return end
    if index > #cases then
        if current ~= -1 then current = -1; warp_to_start_level(); print('[PASSAGES] COMPLETE') end
        return
    end
    local c = cases[index]
    local m, np = gMarioStates[0], gNetworkPlayers[0]
    if current ~= index then
        current, age, attempted = index, 0, false
        print('[PASSAGES] LOAD case=' .. c[1] .. ' result=' .. tostring(warp_to_level(c[2], 1, 1)))
    end
    age = age + 1
    if np.currLevelNum == c[2] and age >= 150 and not attempted then
        if index == 1 or index == 3 then
            local door = one_star_door()
            if door ~= nil then
                position(m, door.oPosX, door.oPosY, door.oPosZ + 100)
                set_mario_action(m, ACT_WALKING, 0)
                local result = interact_door(m, INTERACT_DOOR, door)
                print(string.format('[PASSAGES] DOOR case=%s stars=%d action=%d lockedDialog=%s unlock=%s result=%s doorX=%d doorZ=%d',
                    c[1], m.numStars, m.action, tostring(m.action == ACT_READING_AUTOMATIC_DIALOG),
                    tostring(m.action == ACT_UNLOCKING_STAR_DOOR), tostring(result), door.oPosX, door.oPosZ))
                attempted = true
            elseif age == 150 then print('[PASSAGES] ERROR no-one-star-door') end
        elseif index == 2 then
            -- Collect an existing level star, not a spawned reward or a save write.
            if network_is_server() then
                local star = obj_get_first_with_behavior_id(id_bhvStar)
                if star ~= nil then
                    position(m, star.oPosX, star.oPosY, star.oPosZ)
                    print(string.format('[PASSAGES] EXISTING_STAR params=%d x=%d y=%d z=%d', star.oBehParams, star.oPosX, star.oPosY, star.oPosZ))
                    attempted = true
                elseif age == 150 then print('[PASSAGES] ERROR no-existing-star') end
            end
        elseif index == 4 then
            position(m, 4200, -500, 0)
            print('[PASSAGES] APPROACH DDD floor=' .. tostring(m.floor and m.floor.type))
            attempted = true
        elseif index == 5 then
            position(m, 352, -1490, -3300)
            print('[PASSAGES] APPROACH WDW floor=' .. tostring(m.floor and m.floor.type))
            attempted = true
        end
    end
    if age % 30 == 0 then
        print(string.format('[PASSAGES] STATE case=%s age=%d level=%d area=%d act=%d stars=%d action=%d health=%d floor=%d x=%.2f y=%.2f z=%.2f flags=%d players=%d',
            c[1], age, np.currLevelNum, np.currAreaIndex, np.currActNum, m.numStars,
            m.action, m.health, m.floor and m.floor.type or -1,
            m.pos.x, m.pos.y, m.pos.z, save_file_get_flags(), network_player_connected_count()))
    end
end)
