local mvb = ui.box.move:AddTab('speedhack')
    local bhop_enabled, speed = false, 55
    local forcesprint = false
    mvb:AddToggle('speedhack_forcesprint', {Text = 'forcesprint',Default = false,Callback = function(first)
        forcesprint = first
    end})
    mvb:AddToggle('speedhack_enabled', {Text = 'speedhack enabled',Default = false,Callback = function(first)
        bhop_enabled = first
    end})
    mvb:AddSlider('speedhack_speed',{ Text = 'speed', Default = 55, Min = 55, Max = 70, Rounding = 0, Suffix = "sps", Compact = false }):OnChanged(function(State)
        speed = State
    end)
    local niga, wtf = speed, 0
    local middle = trident.middlepart
    cheat.utility.new_renderstepped(LPH_JIT_MAX(function(delta)
        if bhop_enabled and middle and _IsKeyDown(UserInputService, Enum.KeyCode.C) and _IsKeyDown(UserInputService, Enum.KeyCode.LeftShift) then
            local cameralook = Camera.CFrame.LookVector
            cameralook = _Vector3new(cameralook.X, 0, cameralook.Z)
            local direction = Vector3.zero
            direction = _IsKeyDown(UserInputService, Enum.KeyCode.W) and direction + cameralook or direction;
            direction = _IsKeyDown(UserInputService, Enum.KeyCode.S) and direction - cameralook or direction;
            direction = _IsKeyDown(UserInputService, Enum.KeyCode.D) and direction + _Vector3new(- cameralook.Z, 0, cameralook.X) or direction;
            direction = _IsKeyDown(UserInputService, Enum.KeyCode.A) and direction + _Vector3new(cameralook.Z, 0, - cameralook.X) or direction;
            if not (direction == Vector3.zero) then
                direction = direction.Unit
            end
            niga = math.clamp(niga-delta*20, 17, speed)
            if wtf == 0 then
                middle.CFrame = middle.CFrame + _Vector3new(0, 6.5, 0)
            end
            middle.AssemblyLinearVelocity = _Vector3new(
                direction.X * niga,
                wtf < 0.85 and 0 or -7,
                direction.Z * niga
            )
            wtf = wtf + delta
        else
            if forcesprint and middle then
                local cameralook = Camera.CFrame.LookVector
                cameralook = _Vector3new(cameralook.X, 0, cameralook.Z)
                local direction = Vector3.zero
                direction = _IsKeyDown(UserInputService, Enum.KeyCode.W) and direction + cameralook or direction;
                direction = _IsKeyDown(UserInputService, Enum.KeyCode.S) and direction - cameralook or direction;
                direction = _IsKeyDown(UserInputService, Enum.KeyCode.D) and direction + _Vector3new(- cameralook.Z, 0, cameralook.X) or direction;
                direction = _IsKeyDown(UserInputService, Enum.KeyCode.A) and direction + _Vector3new(cameralook.Z, 0, - cameralook.X) or direction;
                if not (direction == Vector3.zero) then
                    direction = direction.Unit
                end
                middle.AssemblyLinearVelocity = _Vector3new(
                    direction.X * 18,
                    middle.AssemblyLinearVelocity.Y,
                    direction.Z * 18
                )
            end
            niga = speed
            wtf = 0
        end
    end))
end
