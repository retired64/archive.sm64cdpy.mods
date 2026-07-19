-- name:120 stars requirement
-- description:for those who beat the game early \nMod by Blocky

function star(m)
    if m.numStars < 120 and
    gNetworkPlayers[0].currLevelNum == LEVEL_BOWSER_3 then
        warp_to_level(LEVEL_CASTLE_GROUNDS, 1, 0)
    end
end

hook_event(HOOK_MARIO_UPDATE, star)