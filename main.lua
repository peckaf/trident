-- FABRICATED VALUES!!!
local type_custom = typeof
if not LPH_OBFUSCATED then
	LPH_JIT = function(...)
		return ...;
	end;
	LPH_JIT_MAX = function(...)
		return ...;
	end;
	LPH_NO_VIRTUALIZE = function(...)
		return ...;
	end;
	LPH_NO_UPVALUES = function(f)
		return (function(...)
			return f(...);
		end);
	end;
	LPH_ENCSTR = function(...)
		return ...;
	end;
	LPH_ENCNUM = function(...)
		return ...;
	end;
	LPH_ENCFUNC = function(func, key1, key2)
		if key1 ~= key2 then return print("LPH_ENCFUNC mismatch") end
		return func
	end
	LPH_CRASH = function()
		return print(debug.traceback());
	end;
    SWG_DiscordUser = "swim"
    SWG_DiscordID = 1337
    SWG_Private = true
    SWG_Dev = false
    SWG_Version = "free"
    SWG_Title = 'free swimhub.xyz %s - %s | discord.gg/priv9'
    SWG_ShortName = 'free'
    SWG_FullName = 'ts'
    SWG_FFA = false
end;
--- FABRICATED VALUES END!!!

local workspace = cloneref(game:GetService("Workspace"))
local Players = cloneref(game:GetService("Players"))
local RunService = cloneref(game:GetService("RunService"))
local Lighting = cloneref(game:GetService("Lighting"))
local UserInputService = cloneref(game:GetService("UserInputService"))
local HttpService = cloneref(game:GetService("HttpService"))
local GuiInset = cloneref(game:GetService("GuiService")):GetGuiInset()
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local Camera = workspace.CurrentCamera

local function getfile(name)
    local repo = "https://raw.githubusercontent.com/SWIMHUBISWIMMING/swimhub/main/"
    local success, content = pcall(game.HttpGet, game, repo..name)
    if success then return content else return print("getfile returned error \""..content.."\"") end
end
local function isswimhubfile(file)
    return isfile("swimhub/new/files/"..file)
end
local function readswimhubfile(file)
    if not isswimhubfile(file) then return false end
    local success, returns = pcall(readfile, "swimhub/new/files/"..file)
    if success then return returns else return print(returns) end
end
local function loadswimhubfile(file)
    if not isswimhubfile(file) then return false end
    local success, returns = pcall(loadstring, readswimhubfile(file))
    if success then return returns else return print(returns) end
end
local function getswimhubasset(file)
    if isswimhubfile(file) then return false end
    local success, returns = pcall(getcustomasset, "swimhub/new/files/"..file)
    if success then return returns else return print(returns) end
end
do
    if not isfolder("swimhub") then makefolder("swimhub") end
    if not isfolder("swimhub/new") then makefolder("swimhub/new") end
    if not isfolder("swimhub/new/files") then makefolder("swimhub/new/files") end
    local function getfiles(force, list)
        for _, file in list do
            if (force or not force and not isswimhubfile(file)) then
                writefile("swimhub/new/files/"..file, getfile(file))
            end
        end
    end
    local gotassets = getfile("assets.json")
    local assets = HttpService:JSONDecode(gotassets)
    local localassets = readswimhubfile("assets.json")
    if localassets then
        localassets = HttpService:JSONDecode(localassets)
        if localassets.version ~= assets.version then
            writefile("swimhub/new/files/assets.json", gotassets)
            getfiles(true, assets.list)
        end
    else
        writefile("swimhub/new/files/assets.json", gotassets)
    end
    getfiles(false, assets.list)
end

-- swimhub main

local cheat = {
    Library = nil,
    Toggles = nil,
    Options = nil,
    ThemeManager = nil,
    SaveManager = nil,
    connections = {
        heartbeats = {},
        renderstepped = {}
    },
    drawings = {},
    hooks = {}
}
cheat.utility = {} do
    cheat.utility.new_heartbeat = function(func)
        local obj = {}
        cheat.connections.heartbeats[func] = func
        function obj:Disconnect()
            if func then
                cheat.connections.heartbeats[func] = nil
                func = nil
            end
        end
        return obj
    end
    cheat.utility.new_renderstepped = function(func)
        local obj = {}
        cheat.connections.renderstepped[func] = func
        function obj:Disconnect()
            if func then
                cheat.connections.renderstepped[func] = nil
                func = nil
            end
        end
        return obj
    end
    cheat.utility.new_drawing = function(drawobj, args)
        local obj = Drawing.new(drawobj)
        for i, v in pairs(args) do
            obj[i] = v
        end
        cheat.drawings[obj] = obj
        return obj
    end
    cheat.utility.new_hook = function(f, newf, usecclosure) LPH_NO_VIRTUALIZE(function()
        if usecclosure then
            local old; old = hookfunction(f, newcclosure(function(...)
                return newf(old, ...)
            end))
            cheat.hooks[f] = old
            return old
        else
            local old; old = hookfunction(f, function(...)
                return newf(old, ...)
            end)
            cheat.hooks[f] = old
            return old
        end
    end)() end
    local connection; connection = RunService.Heartbeat:Connect(LPH_NO_VIRTUALIZE(function(delta)
        for _, func in pairs(cheat.connections.heartbeats) do
            func(delta)
        end
    end))
    local connection1; connection1 = RunService.RenderStepped:Connect(LPH_NO_VIRTUALIZE(function(delta)
        for _, func in pairs(cheat.connections.renderstepped) do
            func(delta)
        end
    end))
    cheat.utility.unload = function()
        connection:Disconnect()
        connection1:Disconnect()
        for key, _ in pairs(cheat.connections.heartbeats) do
            cheat.connections.heartbeats[key] = nil
        end
        for key, _ in pairs(cheat.connections.renderstepped) do
            cheat.connections.heartbeats[key] = nil
        end
        for _, drawing in pairs(cheat.drawings) do
            drawing:Remove()
            cheat.drawings[_] = nil
        end
        for hooked, original in pairs(cheat.hooks) do
            if type(original) == "function" then
                hookfunction(hooked, clonefunction(original))
            else
                hookmetamethod(original["instance"], original["metamethod"], clonefunction(original["func"]))
            end
        end
    end
end

cheat.Library, cheat.Toggles, cheat.Options = loadswimhubfile("library_main.lua")()
cheat.ThemeManager = loadswimhubfile("library_theme.lua")()
cheat.SaveManager = loadswimhubfile("library_save.lua")()
local ui = {
    window = cheat.Library:CreateWindow({
        Title=string.format(
            SWG_Title,
            SWG_Version,
            SWG_FullName
        ),
    Center=true,AutoShow=true,TabPadding=8})
}

local _CFramenew = CFrame.new
local _Vector2new = Vector2.new
local _Vector3new = Vector3.new
local _IsDescendantOf = game.IsDescendantOf
local _FindFirstChild = game.FindFirstChild
local _FindFirstChildOfClass = game.FindFirstChildOfClass
local _Raycast = workspace.Raycast
local _IsKeyDown = UserInputService.IsKeyDown
local _WorldToViewportPoint = Camera.WorldToViewportPoint
local _Vector3zeromin = Vector3.zero.Min
local _Vector2zeromin = Vector2.zero.Min
local _Vector3zeromax = Vector3.zero.Max
local _Vector2zeromax = Vector2.zero.Max
local _IsA = game.IsA
local tablecreate = table.create
local mathfloor = math.floor
local mathround = math.round
local mathclamp = math.clamp
local tostring = tostring
local unpack = unpack
local getupvalues = debug.getupvalues
local getupvalue = debug.getupvalue
local setupvalue = debug.setupvalue
local getconstants = debug.getconstants
local getconstant = debug.getconstant
local setconstant = debug.setconstant
local getstack = debug.getstack
local setstack = debug.setstack
local getinfo = debug.getinfo
local rawget = rawget

ui.tabs = {
    combat = ui.window:AddTab('combat'),
    visuals = ui.window:AddTab('visuals'),
    misc = ui.window:AddTab('misc'),
    config = ui.window:AddTab('config'),
}
ui.box = {
    aimbot = ui.tabs.combat:AddLeftTabbox(),
    esp = ui.tabs.visuals:AddLeftTabbox(),
    cheatvis = ui.tabs.visuals:AddRightTabbox(),
    world = ui.tabs.visuals:AddRightTabbox(),
    move = ui.tabs.misc:AddLeftTabbox(),
    atvfly = ui.tabs.misc:AddLeftTabbox(),
    misc = ui.tabs.misc:AddRightTabbox(),
    themeconfig = ui.tabs.config:AddLeftGroupbox('theme config'),
}

local trident = {
    loaded = false,
    lastpos = nil,
    middlepart = nil,
    tcp = nil,
    original_model = nil
}
--[[
-- no recoil
debug.setconstant(debug.getupvalue(trident.recoil, 10), 2, rawget(rawget(trident.classes, "InputManager"), "InputDevice"))
-- jump shoot

-- no spread / silent
local old; old = hookmetamethod(Random.new(), "__namecall", newcclosure(function(self, ...)
    local args = {...}
    if args[1] == -100 and args[2] == 100 then
        print('nospread')
        return old(self, -1, 1)
    end
    return old(self, ...)
end))
]]
repeat if not pcall(function()
    trident.middlepart = workspace.Const.Ignore.LocalCharacter.Middle
    trident.original_model = game:GetService("ReplicatedStorage").Shared.entities.Player.Model
    trident.tcp = LocalPlayer.TCP
end) then task.wait(0.5) end until trident.middlepart and trident.original_model and trident.tcp

cheat.EspLibrary = {}; LPH_NO_VIRTUALIZE(function()
    local esp_table = {}
    local workspace = cloneref(game:GetService("Workspace"))
    local rservice = cloneref(game:GetService("RunService"))
    local plrs = cloneref(game:GetService("Players"))
    local lplr = plrs.LocalPlayer
    local container = Instance.new("Folder", game:GetService("CoreGui").RobloxGui)
    esp_table = {
        __loaded = false,
        main_settings = {
            textSize = 15,
            textFont = Drawing.Fonts.Monospace,
            distancelimit = false,
            maxdistance = 200,
            useteamcolor = false,
            teamcheck = false,
            sleepcheck = false,
            simplecalc = false
        },
        main_object_settings = {
            textSize = 15,
            textFont = Drawing.Fonts.Monospace,
            distancelimit = false,
            maxdistance = 200,
            useteamcolor = false,
            teamcheck = false,
            sleepcheck = false,
            allowed = {}
        },
        settings = {
            enemy = {
                enabled = false,
    
                box = false,
                box_fill = false,
                realname = false,
                dist = false,
                weapon = false,
                skeleton = false,
    
                box_outline = false,
                realname_outline = false,
                dist_outline = false,
                weapon_outline = false,
    
                box_color = { Color3.new(1, 1, 1), 1 },
                box_fill_color = { Color3.new(1, 0, 0), 0.3 },
                realname_color = { Color3.new(1, 1, 1), 1 },
                dist_color = { Color3.new(1, 1, 1), 1 },
                weapon_color = { Color3.new(1, 1, 1), 1 },
                skeleton_color = { Color3.new(1, 1, 1), 1 },
    
                box_outline_color = { Color3.new(), 1 },
                realname_outline_color = Color3.new(),
                dist_outline_color = Color3.new(),
                weapon_outline_color = Color3.new(),
    
                chams = false,
                chams_visible_only = false,
                chams_fill_color = { Color3.new(1, 1, 1), 0.5 },
                chamsoutline_color = { Color3.new(1, 1, 1), 0 }
            },
            object = {
                enabled = false,

                realname = false,
                realname_outline = false,

                realname_color = { Color3.new(1, 1, 1), 1 },
                realname_outline_color = Color3.new(),

                chams = false,
                chams_visible_only = false,
                chams_fill_color = { Color3.new(1, 1, 1), 0.5 },
                chamsoutline_color = { Color3.new(1, 1, 1), 0 }
            }
        }
    }
    local loaded_plrs = {}
    -- (please update me) vars
    local camera = workspace.CurrentCamera

    -- constants
    local VERTICES = {
        _Vector3new(-1, -1, -1),
        _Vector3new(-1, 1, -1),
        _Vector3new(-1, 1, 1),
        _Vector3new(-1, -1, 1),
        _Vector3new(1, -1, -1),
        _Vector3new(1, 1, -1),
        _Vector3new(1, 1, 1),
        _Vector3new(1, -1, 1)
    }
    local skeleton_order = {
        ["LeftFoot"] = "LeftLowerLeg",
        ["LeftLowerLeg"] = "LeftUpperLeg",
        ["LeftUpperLeg"] = "LowerTorso",
    
        ["RightFoot"] = "RightLowerLeg",
        ["RightLowerLeg"] = "RightUpperLeg",
        ["RightUpperLeg"] = "LowerTorso",
    
        ["LeftHand"] = "LeftLowerArm",
        ["LeftLowerArm"] = "LeftUpperArm",
        ["LeftUpperArm"] = "Torso",
    
        ["RightHand"] = "RightLowerArm",
        ["RightLowerArm"] = "RightUpperArm",
        ["RightUpperArm"] = "Torso",
    
        ["LowerTorso"] = "Torso",
        ["Torso"] = "Head"
    }
    -- functions
    local esp = {}
    esp.create_obj = function(type, args)
        local obj = Drawing.new(type)
        for i, v in args do
            obj[i] = v
        end
        return obj
    end
    local function isBodyPart(name)
        return name == "Head" or name:find("Torso") or name:find("Leg") or name:find("Arm")
    end
    local function getBoundingBox(parts)
        local min, max
        for i = 1, #parts do
            local part = parts[i]
            local cframe, size = part.CFrame, part.Size
    
            min = _Vector3zeromin(min or cframe.Position, (cframe - size * 0.5).Position)
            max = _Vector3zeromax(max or cframe.Position, (cframe + size * 0.5).Position)
        end
    
        local center = (min + max) * 0.5
        local front = _Vector3new(center.X, center.Y, max.Z)
        return _CFramenew(center, front), max - min
    end
    local function worldToScreen(world)
        local screen, inBounds = _WorldToViewportPoint(camera, world)
        return _Vector2new(screen.X, screen.Y), inBounds, screen.Z
    end
    
    local function calculateCorners(cframe, size)
        local corners = tablecreate(#VERTICES)
        for i = 1, #VERTICES do
            corners[i] = worldToScreen((cframe + size * 0.5 * VERTICES[i]).Position)
        end
    
        local min = _Vector2zeromin(camera.ViewportSize, unpack(corners))
        local max = _Vector2zeromax(Vector2.zero, unpack(corners))
        return {
            corners = corners,
            topLeft = _Vector2new(mathfloor(min.X), mathfloor(min.Y)),
            topRight = _Vector2new(mathfloor(max.X), mathfloor(min.Y)),
            bottomLeft = _Vector2new(mathfloor(min.X), mathfloor(max.Y)),
            bottomRight = _Vector2new(mathfloor(max.X), mathfloor(max.Y))
        }
    end

    local function calculateCornersSimple(head, hrp)
        --[[
            auto head_position = roblox::WorldToScreen(vector3_sub(head.GetPartPosition(), { 0, -0.5, 0 }), dimensions, viewmatrix);
			auto leg_position = roblox::WorldToScreen(vector3_sub(rootpart.GetPartPosition(), { 0, 3.5, 0 }), dimensions, viewmatrix);
            float height = leg_position.y - head_position.y;
			float width = height / 3.6f;
            corners = {
			    {
			        static_cast<int>(round(head_position.x - width)),
			        static_cast<int>(round(head_position.y))
			    }, // up left corner
				{
			        static_cast<int>(round(head_position.x - width)),
			        static_cast<int>(round(leg_position.y))
			    }, // down left corner
				{
			        static_cast<int>(round(head_position.x + width)),
			        static_cast<int>(round(head_position.y))
			    }, // up right corner
			    {
			        static_cast<int>(round(head_position.x + width)),
			        static_cast<int>(round(leg_position.y))
			    } // down right corner
			};
        ]]
        local head_position = worldToScreen(head.Position - Vector3.yAxis * 0.5)
        local leg_position = worldToScreen(hrp.Position - Vector3.yAxis * 3.5)
        local headx, heady = head_position.X, head_position.Y
        local legx, legy = leg_position.X, leg_position.Y
        local height = legy - heady;
        local width = height / 3.6
        return {
            topLeft = _Vector2new(headx - width, heady),
            topRight = _Vector2new(headx - width, legy),
            bottomLeft = _Vector2new(headx + width, heady),
            bottomRight =_Vector2new(headx + width, legy)
        }
    end

    local enttiyidentification = {}
    for i, v in game:GetService("ReplicatedStorage").Shared.entities:GetChildren() do
        local model = _FindFirstChild(v, "Model")
        if model and model.PrimaryPart then
            enttiyidentification[v.Name] = {
                CollisionGroup = model.PrimaryPart.CollisionGroup,
                Material = model.PrimaryPart.Material,
                Color = model.PrimaryPart.Color
            }
        end
    end
    local function identify_model(model)
        if model.ClassName ~= "Model" then return false, false end
        if _FindFirstChildOfClass(model, "MeshPart") and _FindFirstChildOfClass(model, "MeshPart").MeshId == "rbxassetid://12939036056" then
            if #model:GetChildren() == 1 then
                return "Stone", model:GetChildren()[1]
            else
                for _, part in model:GetChildren() do
                    if part.Color == Color3.fromRGB(248, 248, 248) then
                        return "Nitrate", part
                    elseif part.Color == Color3.fromRGB(199, 172, 120) then
                        return "Iron", part
                    end
                end
            end
        end
        if not model.PrimaryPart then return end
        local primpart = model.PrimaryPart
        for name, entity in enttiyidentification do
            if entity.Color == primpart.Color and entity.Material == primpart.Material and entity.CollisionGroup == primpart.CollisionGroup then
                return name, primpart
            end
        end
        return false, false
    end

    local function deepcopy(original)	
        local copy = {}
        for key, value in original do
            copy[key] = type(value) == "table" and deepcopy(value) or value
        end
        return copy
    end
