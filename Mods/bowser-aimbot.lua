-- name: Bowser throw aimbot

local function detect_object_hitbox_overlap(a, b)
    local aY = a.oPosY - a.hitboxDownOffset
    local bY = b.oPosY - b.hitboxDownOffset
    local dx = a.oPosX - b.oPosX
    local dz = a.oPosZ - b.oPosZ
    local collisionRadius = a.hitboxRadius + b.hitboxRadius
    local distance = math.sqrt(dx * dx + dz * dz)

    if collisionRadius > distance then
        local aHeight = a.hitboxHeight + aY
        local bHeight = b.hitboxHeight + bY

        if aY > bHeight or bY > aHeight then return false end
        if a.numCollidedObjs >= 4 or b.numCollidedObjs >= 4 then return false end
        return true
    end
    return false
end

-- translated from vanilla C decomp
local function adjust_analog_stick(controller)
    -- Reset the controller's x and y floats.
    controller.stickX = 0
    controller.stickY = 0

    -- Modulate the rawStickX and rawStickY to be the new f32 values by adding/subtracting 6.
    if controller.rawStickX <= -8 then
        controller.stickX = controller.rawStickX + 6
    elseif controller.rawStickX >= 8 then
        controller.stickX = controller.rawStickX - 6
    end

    if controller.rawStickY <= -8 then
        controller.stickY = controller.rawStickY + 6
    elseif controller.rawStickY >= 8 then
        controller.stickY = controller.rawStickY - 6
    end

    -- Calculate magnitude from the center by vector length.
    controller.stickMag = math.sqrt(controller.stickX ^ 2 + controller.stickY ^ 2)

    -- Magnitude cannot exceed 64: if it does, modify the values appropriately to
    -- flatten the values down to the allowed maximum value.
    if controller.stickMag > 64 then
        controller.stickX = controller.stickX * 64 / controller.stickMag
        controller.stickY = controller.stickY * 64 / controller.stickMag
        controller.stickMag = 64
    end
end

local function pos_angle_to_pos(pos, pos2)
    return atan2s(pos2.z - pos.z, pos2.x - pos.x)
end

local sSlowDown = 0
hook_event(HOOK_BEFORE_MARIO_UPDATE, function (m)
    if m.playerIndex ~= 0 then return end

    if m.action == ACT_HOLDING_BOWSER and not is_game_paused() then
        local bowser = obj_get_first_with_behavior_id(id_bhvBowser)

        -- Find the closest mine to Mario
        local nearestMineDist = 99999
        local mine = obj_get_first_with_behavior_id(id_bhvBowserBomb)
        local targetMine = mine
        while mine ~= nil do
            local dist = math.sqrt((mine.oPosX - m.pos.x)^2 + (mine.oPosZ - m.pos.z)^2)
            if dist < nearestMineDist then
                nearestMineDist = dist
                targetMine = mine
            end
            mine = obj_get_next_with_same_behavior_id(mine)
        end

        if not targetMine then
            -- djui_chat_message_create("no bombs!")
            return
        end

        local throwVel = bowser.oBowserHeldAngleVelYaw / 3000 * 70
        if throwVel < 0 then throwVel = -throwVel end
        local isBowserThrowBig = throwVel > 90
        if isBowserThrowBig then throwVel = throwVel * 2.5 end

        -- Automatically throw bowser
        if m.actionArg ~= 0 and isBowserThrowBig then

            -- Throw Bowser at the right time
            -- Simulate a hitbox collision to check if the current angle is right
            local bowserInPredictedPos = {
                oPosX = m.pos.x + (nearestMineDist * sins(m.faceAngle.y)),
                oPosY = targetMine.oPosY,
                oPosZ = m.pos.z + (nearestMineDist * coss(m.faceAngle.y)),
                hitboxDownOffset = bowser.hitboxDownOffset,
                hitboxRadius = bowser.hitboxRadius,
                hitboxHeight = bowser.hitboxHeight,
                numCollidedObjs = bowser.numCollidedObjs,
            }
            if detect_object_hitbox_overlap(bowserInPredictedPos, targetMine) then
                m.controller.buttonPressed = m.controller.buttonPressed | B_BUTTON
            else

                -- Did we just miss the throw due to spinning Bowser too fast?
                local mineAngle = pos_angle_to_pos(m.pos, { x = targetMine.oPosX, z = targetMine.oPosZ })
                local angleDiff = math.abs(m.faceAngle.y - mineAngle)
                local nextAngleDiff = math.abs((m.faceAngle.y + m.angleVel.y) - mineAngle)
                if angleDiff < math.abs(m.angleVel.y) and nextAngleDiff >= math.abs(m.angleVel.y) then
                    -- djui_chat_message_create(
                    --     "cannot hit closest bomb at " ..
                    --     (math.abs(m.angleVel.y) >= 0x1000 and "max" or ("this (" .. math.abs(m.angleVel.y) .. ")")) ..
                    --     " speed from here, spinning again.."
                    -- )
                    sSlowDown = 5
                end
            end
        end

        -- Automatically spin the stick at max speed
        local angle = 0
        if _G.OmmEnabled and _G.OmmApi.omm_get_setting(m, _G.OmmApi.OMM_SETTING_CAMERA) == _G.OmmApi.OMM_SETTING_CAMERA_ON then
            angle = 0xFFFF/2
            if m.marioObj.oTimer % 2 == 0 then angle = 0 end -- Up one frame, down the next, an so on
        else
            angle = m.twirlYaw * 0x80 - m.area.camera.yaw

            -- may as well try
            m.intendedYaw = 0x80
            m.twirlYaw = 0
        end

        m.controller.rawStickX = 200 * sins(angle)
        m.controller.rawStickY = -200 * coss(angle)

        -- Never allow the control stick to be unintentionally all 0s
        if m.controller.rawStickX == 0 and m.controller.rawStickY == 0 then
            m.controller.rawStickY = 200
        end

        -- Occasionally, spinning Bowser at max speed is too much to get an angle that will hit
        -- so slowing down the spin a little is all it needs
        if sSlowDown > 0 then
            m.controller.rawStickX = 0
            m.controller.rawStickY = 0
            sSlowDown = sSlowDown - 1
        end

        adjust_analog_stick(m.controller)
    end
end)
