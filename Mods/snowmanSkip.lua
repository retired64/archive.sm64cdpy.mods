-- name: Snowman Softlock Fix
-- description: Skips the snowman dialog in CCM to get around the softlock that occasionally occurs there. By Isaac

-- Skip snowman dialog
hook_behavior(id_bhvSnowmansBottom, OBJ_LIST_GENACTOR, false, nil, function (o)
    local m = gMarioStates[0]
    if o.oAction == 0 and m.action == ACT_READING_NPC_DIALOG and is_point_within_radius_of_mario(o.oPosX, o.oPosY, o.oPosZ, 400) then
        o.oForwardVel = 10
        o.oAction = 1
        set_mario_action(m, m.heldObj == nil and ACT_IDLE or ACT_HOLD_IDLE, 0)
        if (o.coopFlags & COOP_OBJ_FLAG_NON_SYNC) == 0 then network_send_object(o, true) end
    end
end)
