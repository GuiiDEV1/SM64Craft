-- name: MarioCraft Multiplayer Validation
-- description: Isolated developer scenario. Never installed in the user's game.

local tick = 0
hook_event(HOOK_UPDATE, function()
    if network_player_connected_count() < 2 then return end
    tick = tick + 1
    local stage = tick - 1200
    local host = network_is_server()
    local m = gMarioStates[0]
    if stage == 300 and host then
        gServerSettings.stayInLevelAfterStar = 2
        warp_to_level(LEVEL_BOB, 1, 1)
    end
    if stage == 600 and not host then warp_to_level(LEVEL_BOB, 1, 1) end
    if stage == 750 and host then
        spawn_sync_object(id_bhvStar, E_MODEL_STAR, m.pos.x, m.pos.y + 50, m.pos.z, function(o)
            o.oBehParams = 0x01000000
        end)
    end
    if stage == 1050 and host then warp_to_level(LEVEL_WF, 1, 1) end
    if stage == 1350 and not host then warp_to_level(LEVEL_WF, 1, 1) end
    if stage == 1650 and host then warp_to_start_level() end
    if stage == 1950 and not host then warp_to_start_level() end
    if tick % 90 == 0 then
        local np = gNetworkPlayers[0]
        print(string.format('[MULTIPLAYER-PROBE] tick=%d host=%s level=%d area=%d act=%d stars=%d players=%d', tick, tostring(host), np.currLevelNum, np.currAreaIndex, np.currActNum, m.numStars, network_player_connected_count()))
    end
end)
