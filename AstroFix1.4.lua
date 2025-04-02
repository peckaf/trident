local Library = {
local InputService = game:GetService('UserInputService');
local TextService = game:GetService('TextService');
local CoreGui = game:GetService('CoreGui');
local Teams = game:GetService('Teams');
local Players = game:GetService('Players');
local RunService = game:GetService('RunService')
local TweenService = game:GetService('TweenService');
local RenderStepped = RunService.RenderStepped;
local LocalPlayer = Players.LocalPlayer;
local Mouse = LocalPlayer:GetMouse();

local ProtectGui = protectgui or (syn and syn.protect_gui) or (function() end);

local ScreenGui = Instance.new('ScreenGui');
ProtectGui(ScreenGui);

ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global;
ScreenGui.Parent = CoreGui;

local Toggles = {};
local Options = {};

getgenv().Toggles = Toggles;
getgenv().Options = Options;

local Library = {
    Registry = {};
    RegistryMap = {};

    HudRegistry = {};

    FontColor = Color3.fromRGB(255, 255, 255);
    MainColor = Color3.fromRGB(28, 28, 28);
    BackgroundColor = Color3.fromRGB(20, 20, 20);
    AccentColor = Color3.fromRGB(0, 85, 255);
    OutlineColor = Color3.fromRGB(50, 50, 50);
    RiskColor = Color3.fromRGB(255, 50, 50),

    Black = Color3.new(0, 0, 0);
    Font = Enum.Font.Code,

    OpenedFrames = {};
    DependencyBoxes = {};

    Signals = {};
    ScreenGui = ScreenGui;
};

local RainbowStep = 0
local Hue = 0

table.insert(Library.Signals, RenderStepped:Connect(function(Delta)
    RainbowStep = RainbowStep + Delta

    if RainbowStep >= (1 / 60) then
        RainbowStep = 0

        Hue = Hue + (1 / 400);

        if Hue > 1 then
            Hue = 0;
        end;

        Library.CurrentRainbowHue = Hue;
        Library.CurrentRainbowColor = Color3.fromHSV(Hue, 0.8, 1);
    end
end))

local function GetPlayersString()
    local PlayerList = Players:GetPlayers();

    for i = 1, #PlayerList do
        PlayerList[i] = PlayerList[i].Name;
    end;

    table.sort(PlayerList, function(str1, str2) return str1 < str2 end);

    return PlayerList;
end;

local function GetTeamsString()
    local TeamList = Teams:GetTeams();

    for i = 1, #TeamList do
        TeamList[i] = TeamList[i].Name;
    end;

    table.sort(TeamList, function(str1, str2) return str1 < str2 end);
    
    return TeamList;
end;

function Library:SafeCallback(f, ...)
    if (not f) then
        return;
    end;

    if not Library.NotifyOnError then
        return f(...);
    end;

    local success, event = pcall(f, ...);

    if not success then
        local _, i = event:find(":%d+: ");

        if not i then
            return Library:Notify(event);
        end;

        return Library:Notify(event:sub(i + 1), 3);
    end;
end;

function Library:AttemptSave()
    if Library.SaveManager then
        Library.SaveManager:Save();
    end;
end;

function Library:Create(Class, Properties)
    local _Instance = Class;

    if type(Class) == 'string' then
        _Instance = Instance.new(Class);
    end;

    for Property, Value in next, Properties do
        _Instance[Property] = Value;
    end;

    return _Instance;
end;

function Library:ApplyTextStroke(Inst)
    Inst.TextStrokeTransparency = 1;

    Library:Create('UIStroke', {
        Color = Color3.new(0, 0, 0);
        Thickness = 1;
        LineJoinMode = Enum.LineJoinMode.Miter;
        Parent = Inst;
    });
end;

function Library:CreateLabel(Properties, IsHud)
    local _Instance = Library:Create('TextLabel', {
        BackgroundTransparency = 1;
        Font = Library.Font;
        TextColor3 = Library.FontColor;
        TextSize = 16;
        TextStrokeTransparency = 0;
    });

    Library:ApplyTextStroke(_Instance);

    Library:AddToRegistry(_Instance, {
        TextColor3 = 'FontColor';
    }, IsHud);

    return Library:Create(_Instance, Properties);
end;

function Library:MakeDraggable(Instance, Cutoff)
    Instance.Active = true;

    Instance.InputBegan:Connect(function(Input)
        if Input.UserInputType == Enum.UserInputType.MouseButton1 then
            local ObjPos = Vector2.new(
                Mouse.X - Instance.AbsolutePosition.X,
                Mouse.Y - Instance.AbsolutePosition.Y
            );

            if ObjPos.Y > (Cutoff or 40) then
                return;
            end;

            while InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
                Instance.Position = UDim2.new(
                    0,
                    Mouse.X - ObjPos.X + (Instance.Size.X.Offset * Instance.AnchorPoint.X),
                    0,
                    Mouse.Y - ObjPos.Y + (Instance.Size.Y.Offset * Instance.AnchorPoint.Y)
                );

                RenderStepped:Wait();
            end;
        end;
    end)
end;

function Library:AddToolTip(InfoStr, HoverInstance)
    local X, Y = Library:GetTextBounds(InfoStr, Library.Font, 14);
    local Tooltip = Library:Create('Frame', {
        BackgroundColor3 = Library.MainColor,
        BorderColor3 = Library.OutlineColor,

        Size = UDim2.fromOffset(X + 5, Y + 4),
        ZIndex = 100,
        Parent = Library.ScreenGui,

        Visible = false,
    })

    local Label = Library:CreateLabel({
        Position = UDim2.fromOffset(3, 1),
        Size = UDim2.fromOffset(X, Y);
        TextSize = 14;
        Text = InfoStr,
        TextColor3 = Library.FontColor,
        TextXAlignment = Enum.TextXAlignment.Left;
        ZIndex = Tooltip.ZIndex + 1,

        Parent = Tooltip;
    });

    Library:AddToRegistry(Tooltip, {
        BackgroundColor3 = 'MainColor';
        BorderColor3 = 'OutlineColor';
    });

    Library:AddToRegistry(Label, {
        TextColor3 = 'FontColor',
    });

    local IsHovering = false

    HoverInstance.MouseEnter:Connect(function()
        if Library:MouseIsOverOpenedFrame() then
            return
        end

        IsHovering = true

        Tooltip.Position = UDim2.fromOffset(Mouse.X + 15, Mouse.Y + 12)
        Tooltip.Visible = true

        while IsHovering do
            RunService.Heartbeat:Wait()
            Tooltip.Position = UDim2.fromOffset(Mouse.X + 15, Mouse.Y + 12)
        end
    end)

    HoverInstance.MouseLeave:Connect(function()
        IsHovering = false
        Tooltip.Visible = false
    end)
end

function Library:OnHighlight(HighlightInstance, Instance, Properties, PropertiesDefault)
    HighlightInstance.MouseEnter:Connect(function()
        local Reg = Library.RegistryMap[Instance];

        for Property, ColorIdx in next, Properties do
            Instance[Property] = Library[ColorIdx] or ColorIdx;

            if Reg and Reg.Properties[Property] then
                Reg.Properties[Property] = ColorIdx;
            end;
        end;
    end)

    HighlightInstance.MouseLeave:Connect(function()
        local Reg = Library.RegistryMap[Instance];

        for Property, ColorIdx in next, PropertiesDefault do
            Instance[Property] = Library[ColorIdx] or ColorIdx;

            if Reg and Reg.Properties[Property] then
                Reg.Properties[Property] = ColorIdx;
            end;
        end;
    end)
end;

function Library:MouseIsOverOpenedFrame()
    for Frame, _ in next, Library.OpenedFrames do
        local AbsPos, AbsSize = Frame.AbsolutePosition, Frame.AbsoluteSize;

        if Mouse.X >= AbsPos.X and Mouse.X <= AbsPos.X + AbsSize.X
            and Mouse.Y >= AbsPos.Y and Mouse.Y <= AbsPos.Y + AbsSize.Y then

            return true;
        end;
    end;
end;

function Library:IsMouseOverFrame(Frame)
    local AbsPos, AbsSize = Frame.AbsolutePosition, Frame.AbsoluteSize;

    if Mouse.X >= AbsPos.X and Mouse.X <= AbsPos.X + AbsSize.X
        and Mouse.Y >= AbsPos.Y and Mouse.Y <= AbsPos.Y + AbsSize.Y then

        return true;
    end;
end;

function Library:UpdateDependencyBoxes()
    for _, Depbox in next, Library.DependencyBoxes do
        Depbox:Update();
    end;
end;

function Library:MapValue(Value, MinA, MaxA, MinB, MaxB)
    return (1 - ((Value - MinA) / (MaxA - MinA))) * MinB + ((Value - MinA) / (MaxA - MinA)) * MaxB;
end;

function Library:GetTextBounds(Text, Font, Size, Resolution)
    local Bounds = TextService:GetTextSize(Text, Size, Font, Resolution or Vector2.new(1920, 1080))
    return Bounds.X, Bounds.Y
end;

function Library:GetDarkerColor(Color)
    local H, S, V = Color3.toHSV(Color);
    return Color3.fromHSV(H, S, V / 1.5);
end;
Library.AccentColorDark = Library:GetDarkerColor(Library.AccentColor);

function Library:AddToRegistry(Instance, Properties, IsHud)
    local Idx = #Library.Registry + 1;
    local Data = {
        Instance = Instance;
        Properties = Properties;
        Idx = Idx;
    };

    table.insert(Library.Registry, Data);
    Library.RegistryMap[Instance] = Data;

    if IsHud then
        table.insert(Library.HudRegistry, Data);
    end;
end;

function Library:RemoveFromRegistry(Instance)
    local Data = Library.RegistryMap[Instance];

    if Data then
        for Idx = #Library.Registry, 1, -1 do
            if Library.Registry[Idx] == Data then
                table.remove(Library.Registry, Idx);
            end;
        end;

        for Idx = #Library.HudRegistry, 1, -1 do
            if Library.HudRegistry[Idx] == Data then
                table.remove(Library.HudRegistry, Idx);
            end;
        end;

        Library.RegistryMap[Instance] = nil;
    end;
end;

function Library:UpdateColorsUsingRegistry()
    -- TODO: Could have an 'active' list of objects
    -- where the active list only contains Visible objects.

    -- IMPL: Could setup .Changed events on the AddToRegistry function
    -- that listens for the 'Visible' propert being changed.
    -- Visible: true => Add to active list, and call UpdateColors function
    -- Visible: false => Remove from active list.

    -- The above would be especially efficient for a rainbow menu color or live color-changing.

    for Idx, Object in next, Library.Registry do
        for Property, ColorIdx in next, Object.Properties do
            if type(ColorIdx) == 'string' then
                Object.Instance[Property] = Library[ColorIdx];
            elseif type(ColorIdx) == 'function' then
                Object.Instance[Property] = ColorIdx()
            end
        end;
    end;
end;

function Library:GiveSignal(Signal)
    -- Only used for signals not attached to library instances, as those should be cleaned up on object destruction by Roblox
    table.insert(Library.Signals, Signal)
end

function Library:Unload()
    -- Unload all of the signals
    for Idx = #Library.Signals, 1, -1 do
        local Connection = table.remove(Library.Signals, Idx)
        Connection:Disconnect()
    end

     -- Call our unload callback, maybe to undo some hooks etc
    if Library.OnUnload then
        Library.OnUnload()
    end

    ScreenGui:Destroy()
end

function Library:OnUnload(Callback)
    Library.OnUnload = Callback
end

Library:GiveSignal(ScreenGui.DescendantRemoving:Connect(function(Instance)
    if Library.RegistryMap[Instance] then
        Library:RemoveFromRegistry(Instance);
    end;
end))

local BaseAddons = {};

do
    local Funcs = {};

    function Funcs:AddColorPicker(Idx, Info)
        local ToggleLabel = self.TextLabel;
        -- local Container = self.Container;

        assert(Info.Default, 'AddColorPicker: Missing default value.');

        local ColorPicker = {
            Value = Info.Default;
            Transparency = Info.Transparency or 0;
            Type = 'ColorPicker';
            Title = type(Info.Title) == 'string' and Info.Title or 'Color picker',
            Callback = Info.Callback or function(Color) end;
        };

        function ColorPicker:SetHSVFromRGB(Color)
            local H, S, V = Color3.toHSV(Color);

            ColorPicker.Hue = H;
            ColorPicker.Sat = S;
            ColorPicker.Vib = V;
        end;

        ColorPicker:SetHSVFromRGB(ColorPicker.Value);

        local DisplayFrame = Library:Create('Frame', {
            BackgroundColor3 = ColorPicker.Value;
            BorderColor3 = Library:GetDarkerColor(ColorPicker.Value);
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(0, 28, 0, 14);
            ZIndex = 6;
            Parent = ToggleLabel;
        });

        -- Transparency image taken from https://github.com/matas3535/SplixPrivateDrawingLibrary/blob/main/Library.lua cus i'm lazy
        local CheckerFrame = Library:Create('ImageLabel', {
            BorderSizePixel = 0;
            Size = UDim2.new(0, 27, 0, 13);
            ZIndex = 5;
            Image = 'http://www.roblox.com/asset/?id=12977615774';
            Visible = not not Info.Transparency;
            Parent = DisplayFrame;
        });

        -- 1/16/23
        -- Rewrote this to be placed inside the Library ScreenGui
        -- There was some issue which caused RelativeOffset to be way off
        -- Thus the color picker would never show

        local PickerFrameOuter = Library:Create('Frame', {
            Name = 'Color';
            BackgroundColor3 = Color3.new(1, 1, 1);
            BorderColor3 = Color3.new(0, 0, 0);
            Position = UDim2.fromOffset(DisplayFrame.AbsolutePosition.X, DisplayFrame.AbsolutePosition.Y + 18),
            Size = UDim2.fromOffset(230, Info.Transparency and 271 or 253);
            Visible = false;
            ZIndex = 15;
            Parent = ScreenGui,
        });

        DisplayFrame:GetPropertyChangedSignal('AbsolutePosition'):Connect(function()
            PickerFrameOuter.Position = UDim2.fromOffset(DisplayFrame.AbsolutePosition.X, DisplayFrame.AbsolutePosition.Y + 18);
        end)

        local PickerFrameInner = Library:Create('Frame', {
            BackgroundColor3 = Library.BackgroundColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 16;
            Parent = PickerFrameOuter;
        });

        local Highlight = Library:Create('Frame', {
            BackgroundColor3 = Library.AccentColor;
            BorderSizePixel = 0;
            Size = UDim2.new(1, 0, 0, 2);
            ZIndex = 17;
            Parent = PickerFrameInner;
        });

        local SatVibMapOuter = Library:Create('Frame', {
            BorderColor3 = Color3.new(0, 0, 0);
            Position = UDim2.new(0, 4, 0, 25);
            Size = UDim2.new(0, 200, 0, 200);
            ZIndex = 17;
            Parent = PickerFrameInner;
        });

        local SatVibMapInner = Library:Create('Frame', {
            BackgroundColor3 = Library.BackgroundColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 18;
            Parent = SatVibMapOuter;
        });

        local SatVibMap = Library:Create('ImageLabel', {
            BorderSizePixel = 0;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 18;
            Image = 'rbxassetid://4155801252';
            Parent = SatVibMapInner;
        });

        local CursorOuter = Library:Create('ImageLabel', {
            AnchorPoint = Vector2.new(0.5, 0.5);
            Size = UDim2.new(0, 6, 0, 6);
            BackgroundTransparency = 1;
            Image = 'http://www.roblox.com/asset/?id=9619665977';
            ImageColor3 = Color3.new(0, 0, 0);
            ZIndex = 19;
            Parent = SatVibMap;
        });

        local CursorInner = Library:Create('ImageLabel', {
            Size = UDim2.new(0, CursorOuter.Size.X.Offset - 2, 0, CursorOuter.Size.Y.Offset - 2);
            Position = UDim2.new(0, 1, 0, 1);
            BackgroundTransparency = 1;
            Image = 'http://www.roblox.com/asset/?id=9619665977';
            ZIndex = 20;
            Parent = CursorOuter;
        })

        local HueSelectorOuter = Library:Create('Frame', {
            BorderColor3 = Color3.new(0, 0, 0);
            Position = UDim2.new(0, 208, 0, 25);
            Size = UDim2.new(0, 15, 0, 200);
            ZIndex = 17;
            Parent = PickerFrameInner;
        });

        local HueSelectorInner = Library:Create('Frame', {
            BackgroundColor3 = Color3.new(1, 1, 1);
            BorderSizePixel = 0;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 18;
            Parent = HueSelectorOuter;
        });

        local HueCursor = Library:Create('Frame', { 
            BackgroundColor3 = Color3.new(1, 1, 1);
            AnchorPoint = Vector2.new(0, 0.5);
            BorderColor3 = Color3.new(0, 0, 0);
            Size = UDim2.new(1, 0, 0, 1);
            ZIndex = 18;
            Parent = HueSelectorInner;
        });

        local HueBoxOuter = Library:Create('Frame', {
            BorderColor3 = Color3.new(0, 0, 0);
            Position = UDim2.fromOffset(4, 228),
            Size = UDim2.new(0.5, -6, 0, 20),
            ZIndex = 18,
            Parent = PickerFrameInner;
        });

        local HueBoxInner = Library:Create('Frame', {
            BackgroundColor3 = Library.MainColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 18,
            Parent = HueBoxOuter;
        });

        Library:Create('UIGradient', {
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(212, 212, 212))
            });
            Rotation = 90;
            Parent = HueBoxInner;
        });

        local HueBox = Library:Create('TextBox', {
            BackgroundTransparency = 1;
            Position = UDim2.new(0, 5, 0, 0);
            Size = UDim2.new(1, -5, 1, 0);
            Font = Library.Font;
            PlaceholderColor3 = Color3.fromRGB(190, 190, 190);
            PlaceholderText = 'Hex color',
            Text = '#FFFFFF',
            TextColor3 = Library.FontColor;
            TextSize = 14;
            TextStrokeTransparency = 0;
            TextXAlignment = Enum.TextXAlignment.Left;
            ZIndex = 20,
            Parent = HueBoxInner;
        });

        Library:ApplyTextStroke(HueBox);

        local RgbBoxBase = Library:Create(HueBoxOuter:Clone(), {
            Position = UDim2.new(0.5, 2, 0, 228),
            Size = UDim2.new(0.5, -6, 0, 20),
            Parent = PickerFrameInner
        });

        local RgbBox = Library:Create(RgbBoxBase.Frame:FindFirstChild('TextBox'), {
            Text = '255, 255, 255',
            PlaceholderText = 'RGB color',
            TextColor3 = Library.FontColor
        });

        local TransparencyBoxOuter, TransparencyBoxInner, TransparencyCursor;
        
        if Info.Transparency then 
            TransparencyBoxOuter = Library:Create('Frame', {
                BorderColor3 = Color3.new(0, 0, 0);
                Position = UDim2.fromOffset(4, 251);
                Size = UDim2.new(1, -8, 0, 15);
                ZIndex = 19;
                Parent = PickerFrameInner;
            });

            TransparencyBoxInner = Library:Create('Frame', {
                BackgroundColor3 = ColorPicker.Value;
                BorderColor3 = Library.OutlineColor;
                BorderMode = Enum.BorderMode.Inset;
                Size = UDim2.new(1, 0, 1, 0);
                ZIndex = 19;
                Parent = TransparencyBoxOuter;
            });

            Library:AddToRegistry(TransparencyBoxInner, { BorderColor3 = 'OutlineColor' });

            Library:Create('ImageLabel', {
                BackgroundTransparency = 1;
                Size = UDim2.new(1, 0, 1, 0);
                Image = 'http://www.roblox.com/asset/?id=12978095818';
                ZIndex = 20;
                Parent = TransparencyBoxInner;
            });

            TransparencyCursor = Library:Create('Frame', { 
                BackgroundColor3 = Color3.new(1, 1, 1);
                AnchorPoint = Vector2.new(0.5, 0);
                BorderColor3 = Color3.new(0, 0, 0);
                Size = UDim2.new(0, 1, 1, 0);
                ZIndex = 21;
                Parent = TransparencyBoxInner;
            });
        end;

        local DisplayLabel = Library:CreateLabel({
            Size = UDim2.new(1, 0, 0, 14);
            Position = UDim2.fromOffset(5, 5);
            TextXAlignment = Enum.TextXAlignment.Left;
            TextSize = 14;
            Text = ColorPicker.Title,--Info.Default;
            TextWrapped = false;
            ZIndex = 16;
            Parent = PickerFrameInner;
        });


        local ContextMenu = {}
        do
            ContextMenu.Options = {}
            ContextMenu.Container = Library:Create('Frame', {
                BorderColor3 = Color3.new(),
                ZIndex = 14,

                Visible = false,
                Parent = ScreenGui
            })

            ContextMenu.Inner = Library:Create('Frame', {
                BackgroundColor3 = Library.BackgroundColor;
                BorderColor3 = Library.OutlineColor;
                BorderMode = Enum.BorderMode.Inset;
                Size = UDim2.fromScale(1, 1);
                ZIndex = 15;
                Parent = ContextMenu.Container;
            });

            Library:Create('UIListLayout', {
                Name = 'Layout',
                FillDirection = Enum.FillDirection.Vertical;
                SortOrder = Enum.SortOrder.LayoutOrder;
                Parent = ContextMenu.Inner;
            });

            Library:Create('UIPadding', {
                Name = 'Padding',
                PaddingLeft = UDim.new(0, 4),
                Parent = ContextMenu.Inner,
            });

            local function updateMenuPosition()
                ContextMenu.Container.Position = UDim2.fromOffset(
                    (DisplayFrame.AbsolutePosition.X + DisplayFrame.AbsoluteSize.X) + 4,
                    DisplayFrame.AbsolutePosition.Y + 1
                )
            end

            local function updateMenuSize()
                local menuWidth = 60
                for i, label in next, ContextMenu.Inner:GetChildren() do
                    if label:IsA('TextLabel') then
                        menuWidth = math.max(menuWidth, label.TextBounds.X)
                    end
                end

                ContextMenu.Container.Size = UDim2.fromOffset(
                    menuWidth + 8,
                    ContextMenu.Inner.Layout.AbsoluteContentSize.Y + 4
                )
            end

            DisplayFrame:GetPropertyChangedSignal('AbsolutePosition'):Connect(updateMenuPosition)
            ContextMenu.Inner.Layout:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(updateMenuSize)

            task.spawn(updateMenuPosition)
            task.spawn(updateMenuSize)

            Library:AddToRegistry(ContextMenu.Inner, {
                BackgroundColor3 = 'BackgroundColor';
                BorderColor3 = 'OutlineColor';
            });

            function ContextMenu:Show()
                self.Container.Visible = true
            end

            function ContextMenu:Hide()
                self.Container.Visible = false
            end

            function ContextMenu:AddOption(Str, Callback)
                if type(Callback) ~= 'function' then
                    Callback = function() end
                end

                local Button = Library:CreateLabel({
                    Active = false;
                    Size = UDim2.new(1, 0, 0, 15);
                    TextSize = 13;
                    Text = Str;
                    ZIndex = 16;
                    Parent = self.Inner;
                    TextXAlignment = Enum.TextXAlignment.Left,
                });

                Library:OnHighlight(Button, Button, 
                    { TextColor3 = 'AccentColor' },
                    { TextColor3 = 'FontColor' }
                );

                Button.InputBegan:Connect(function(Input)
                    if Input.UserInputType ~= Enum.UserInputType.MouseButton1 then
                        return
                    end

                    Callback()
                end)
            end

            ContextMenu:AddOption('Copy color', function()
                Library.ColorClipboard = ColorPicker.Value
                Library:Notify('Copied color!', 2)
            end)

            ContextMenu:AddOption('Paste color', function()
                if not Library.ColorClipboard then
                    return Library:Notify('You have not copied a color!', 2)
                end
                ColorPicker:SetValueRGB(Library.ColorClipboard)
            end)


            ContextMenu:AddOption('Copy HEX', function()
                pcall(setclipboard, ColorPicker.Value:ToHex())
                Library:Notify('Copied hex code to clipboard!', 2)
            end)

            ContextMenu:AddOption('Copy RGB', function()
                pcall(setclipboard, table.concat({ math.floor(ColorPicker.Value.R * 255), math.floor(ColorPicker.Value.G * 255), math.floor(ColorPicker.Value.B * 255) }, ', '))
                Library:Notify('Copied RGB values to clipboard!', 2)
            end)

        end

        Library:AddToRegistry(PickerFrameInner, { BackgroundColor3 = 'BackgroundColor'; BorderColor3 = 'OutlineColor'; });
        Library:AddToRegistry(Highlight, { BackgroundColor3 = 'AccentColor'; });
        Library:AddToRegistry(SatVibMapInner, { BackgroundColor3 = 'BackgroundColor'; BorderColor3 = 'OutlineColor'; });

        Library:AddToRegistry(HueBoxInner, { BackgroundColor3 = 'MainColor'; BorderColor3 = 'OutlineColor'; });
        Library:AddToRegistry(RgbBoxBase.Frame, { BackgroundColor3 = 'MainColor'; BorderColor3 = 'OutlineColor'; });
        Library:AddToRegistry(RgbBox, { TextColor3 = 'FontColor', });
        Library:AddToRegistry(HueBox, { TextColor3 = 'FontColor', });

        local SequenceTable = {};

        for Hue = 0, 1, 0.1 do
            table.insert(SequenceTable, ColorSequenceKeypoint.new(Hue, Color3.fromHSV(Hue, 1, 1)));
        end;

        local HueSelectorGradient = Library:Create('UIGradient', {
            Color = ColorSequence.new(SequenceTable);
            Rotation = 90;
            Parent = HueSelectorInner;
        });

        HueBox.FocusLost:Connect(function(enter)
            if enter then
                local success, result = pcall(Color3.fromHex, HueBox.Text)
                if success and typeof(result) == 'Color3' then
                    ColorPicker.Hue, ColorPicker.Sat, ColorPicker.Vib = Color3.toHSV(result)
                end
            end

            ColorPicker:Display()
        end)

        RgbBox.FocusLost:Connect(function(enter)
            if enter then
                local r, g, b = RgbBox.Text:match('(%d+),%s*(%d+),%s*(%d+)')
                if r and g and b then
                    ColorPicker.Hue, ColorPicker.Sat, ColorPicker.Vib = Color3.toHSV(Color3.fromRGB(r, g, b))
                end
            end

            ColorPicker:Display()
        end)

        function ColorPicker:Display()
            ColorPicker.Value = Color3.fromHSV(ColorPicker.Hue, ColorPicker.Sat, ColorPicker.Vib);
            SatVibMap.BackgroundColor3 = Color3.fromHSV(ColorPicker.Hue, 1, 1);

            Library:Create(DisplayFrame, {
                BackgroundColor3 = ColorPicker.Value;
                BackgroundTransparency = ColorPicker.Transparency;
                BorderColor3 = Library:GetDarkerColor(ColorPicker.Value);
            });

            if TransparencyBoxInner then
                TransparencyBoxInner.BackgroundColor3 = ColorPicker.Value;
                TransparencyCursor.Position = UDim2.new(1 - ColorPicker.Transparency, 0, 0, 0);
            end;

            CursorOuter.Position = UDim2.new(ColorPicker.Sat, 0, 1 - ColorPicker.Vib, 0);
            HueCursor.Position = UDim2.new(0, 0, ColorPicker.Hue, 0);

            HueBox.Text = '#' .. ColorPicker.Value:ToHex()
            RgbBox.Text = table.concat({ math.floor(ColorPicker.Value.R * 255), math.floor(ColorPicker.Value.G * 255), math.floor(ColorPicker.Value.B * 255) }, ', ')

            Library:SafeCallback(ColorPicker.Callback, ColorPicker.Value);
            Library:SafeCallback(ColorPicker.Changed, ColorPicker.Value);
        end;

        function ColorPicker:OnChanged(Func)
            ColorPicker.Changed = Func;
            Func(ColorPicker.Value)
        end;

        function ColorPicker:Show()
            for Frame, Val in next, Library.OpenedFrames do
                if Frame.Name == 'Color' then
                    Frame.Visible = false;
                    Library.OpenedFrames[Frame] = nil;
                end;
            end;

            PickerFrameOuter.Visible = true;
            Library.OpenedFrames[PickerFrameOuter] = true;
        end;

        function ColorPicker:Hide()
            PickerFrameOuter.Visible = false;
            Library.OpenedFrames[PickerFrameOuter] = nil;
        end;

        function ColorPicker:SetValue(HSV, Transparency)
            local Color = Color3.fromHSV(HSV[1], HSV[2], HSV[3]);

            ColorPicker.Transparency = Transparency or 0;
            ColorPicker:SetHSVFromRGB(Color);
            ColorPicker:Display();
        end;

        function ColorPicker:SetValueRGB(Color, Transparency)
            ColorPicker.Transparency = Transparency or 0;
            ColorPicker:SetHSVFromRGB(Color);
            ColorPicker:Display();
        end;

        SatVibMap.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                while InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
                    local MinX = SatVibMap.AbsolutePosition.X;
                    local MaxX = MinX + SatVibMap.AbsoluteSize.X;
                    local MouseX = math.clamp(Mouse.X, MinX, MaxX);

                    local MinY = SatVibMap.AbsolutePosition.Y;
                    local MaxY = MinY + SatVibMap.AbsoluteSize.Y;
                    local MouseY = math.clamp(Mouse.Y, MinY, MaxY);

                    ColorPicker.Sat = (MouseX - MinX) / (MaxX - MinX);
                    ColorPicker.Vib = 1 - ((MouseY - MinY) / (MaxY - MinY));
                    ColorPicker:Display();

                    RenderStepped:Wait();
                end;

                Library:AttemptSave();
            end;
        end);

        HueSelectorInner.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                while InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
                    local MinY = HueSelectorInner.AbsolutePosition.Y;
                    local MaxY = MinY + HueSelectorInner.AbsoluteSize.Y;
                    local MouseY = math.clamp(Mouse.Y, MinY, MaxY);

                    ColorPicker.Hue = ((MouseY - MinY) / (MaxY - MinY));
                    ColorPicker:Display();

                    RenderStepped:Wait();
                end;

                Library:AttemptSave();
            end;
        end);

        DisplayFrame.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 and not Library:MouseIsOverOpenedFrame() then
                if PickerFrameOuter.Visible then
                    ColorPicker:Hide()
                else
                    ContextMenu:Hide()
                    ColorPicker:Show()
                end;
            elseif Input.UserInputType == Enum.UserInputType.MouseButton2 and not Library:MouseIsOverOpenedFrame() then
                ContextMenu:Show()
                ColorPicker:Hide()
            end
        end);

        if TransparencyBoxInner then
            TransparencyBoxInner.InputBegan:Connect(function(Input)
                if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                    while InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
                        local MinX = TransparencyBoxInner.AbsolutePosition.X;
                        local MaxX = MinX + TransparencyBoxInner.AbsoluteSize.X;
                        local MouseX = math.clamp(Mouse.X, MinX, MaxX);

                        ColorPicker.Transparency = 1 - ((MouseX - MinX) / (MaxX - MinX));

                        ColorPicker:Display();

                        RenderStepped:Wait();
                    end;

                    Library:AttemptSave();
                end;
            end);
        end;

        Library:GiveSignal(InputService.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                local AbsPos, AbsSize = PickerFrameOuter.AbsolutePosition, PickerFrameOuter.AbsoluteSize;

                if Mouse.X < AbsPos.X or Mouse.X > AbsPos.X + AbsSize.X
                    or Mouse.Y < (AbsPos.Y - 20 - 1) or Mouse.Y > AbsPos.Y + AbsSize.Y then

                    ColorPicker:Hide();
                end;

                if not Library:IsMouseOverFrame(ContextMenu.Container) then
                    ContextMenu:Hide()
                end
            end;

            if Input.UserInputType == Enum.UserInputType.MouseButton2 and ContextMenu.Container.Visible then
                if not Library:IsMouseOverFrame(ContextMenu.Container) and not Library:IsMouseOverFrame(DisplayFrame) then
                    ContextMenu:Hide()
                end
            end
        end))

        ColorPicker:Display();
        ColorPicker.DisplayFrame = DisplayFrame

        Options[Idx] = ColorPicker;

        return self;
    end;

    function Funcs:AddKeyPicker(Idx, Info)
        local ParentObj = self;
        local ToggleLabel = self.TextLabel;
        local Container = self.Container;

        assert(Info.Default, 'AddKeyPicker: Missing default value.');

        local KeyPicker = {
            Value = Info.Default;
            Toggled = false;
            Mode = Info.Mode or 'Toggle'; -- Always, Toggle, Hold
            Type = 'KeyPicker';
            Callback = Info.Callback or function(Value) end;
            ChangedCallback = Info.ChangedCallback or function(New) end;

            SyncToggleState = Info.SyncToggleState or false;
        };

        if KeyPicker.SyncToggleState then
            Info.Modes = { 'Toggle' }
            Info.Mode = 'Toggle'
        end

        local PickOuter = Library:Create('Frame', {
            BackgroundColor3 = Color3.new(0, 0, 0);
            BorderColor3 = Color3.new(0, 0, 0);
            Size = UDim2.new(0, 28, 0, 15);
            ZIndex = 6;
            Parent = ToggleLabel;
        });

        local PickInner = Library:Create('Frame', {
            BackgroundColor3 = Library.BackgroundColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 7;
            Parent = PickOuter;
        });

        Library:AddToRegistry(PickInner, {
            BackgroundColor3 = 'BackgroundColor';
            BorderColor3 = 'OutlineColor';
        });

        local DisplayLabel = Library:CreateLabel({
            Size = UDim2.new(1, 0, 1, 0);
            TextSize = 13;
            Text = Info.Default;
            TextWrapped = true;
            ZIndex = 8;
            Parent = PickInner;
        });

        local ModeSelectOuter = Library:Create('Frame', {
            BorderColor3 = Color3.new(0, 0, 0);
            Position = UDim2.fromOffset(ToggleLabel.AbsolutePosition.X + ToggleLabel.AbsoluteSize.X + 4, ToggleLabel.AbsolutePosition.Y + 1);
            Size = UDim2.new(0, 60, 0, 45 + 2);
            Visible = false;
            ZIndex = 14;
            Parent = ScreenGui;
        });

        ToggleLabel:GetPropertyChangedSignal('AbsolutePosition'):Connect(function()
            ModeSelectOuter.Position = UDim2.fromOffset(ToggleLabel.AbsolutePosition.X + ToggleLabel.AbsoluteSize.X + 4, ToggleLabel.AbsolutePosition.Y + 1);
        end);

        local ModeSelectInner = Library:Create('Frame', {
            BackgroundColor3 = Library.BackgroundColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 15;
            Parent = ModeSelectOuter;
        });

        Library:AddToRegistry(ModeSelectInner, {
            BackgroundColor3 = 'BackgroundColor';
            BorderColor3 = 'OutlineColor';
        });

        Library:Create('UIListLayout', {
            FillDirection = Enum.FillDirection.Vertical;
            SortOrder = Enum.SortOrder.LayoutOrder;
            Parent = ModeSelectInner;
        });

        local ContainerLabel = Library:CreateLabel({
            TextXAlignment = Enum.TextXAlignment.Left;
            Size = UDim2.new(1, 0, 0, 18);
            TextSize = 13;
            Visible = false;
            ZIndex = 110;
            Parent = Library.KeybindContainer;
        },  true);

        local Modes = Info.Modes or { 'Always', 'Toggle', 'Hold' };
        local ModeButtons = {};

        for Idx, Mode in next, Modes do
            local ModeButton = {};

            local Label = Library:CreateLabel({
                Active = false;
                Size = UDim2.new(1, 0, 0, 15);
                TextSize = 13;
                Text = Mode;
                ZIndex = 16;
                Parent = ModeSelectInner;
            });

            function ModeButton:Select()
                for _, Button in next, ModeButtons do
                    Button:Deselect();
                end;

                KeyPicker.Mode = Mode;

                Label.TextColor3 = Library.AccentColor;
                Library.RegistryMap[Label].Properties.TextColor3 = 'AccentColor';

                ModeSelectOuter.Visible = false;
            end;

            function ModeButton:Deselect()
                KeyPicker.Mode = nil;

                Label.TextColor3 = Library.FontColor;
                Library.RegistryMap[Label].Properties.TextColor3 = 'FontColor';
            end;

            Label.InputBegan:Connect(function(Input)
                if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                    ModeButton:Select();
                    Library:AttemptSave();
                end;
            end);

            if Mode == KeyPicker.Mode then
                ModeButton:Select();
            end;

            ModeButtons[Mode] = ModeButton;
        end;

        function KeyPicker:Update()
            if Info.NoUI then
                return;
            end;

            local State = KeyPicker:GetState();

            ContainerLabel.Text = string.format('[%s] %s (%s)', KeyPicker.Value, Info.Text, KeyPicker.Mode);

            ContainerLabel.Visible = true;
            ContainerLabel.TextColor3 = State and Library.AccentColor or Library.FontColor;

            Library.RegistryMap[ContainerLabel].Properties.TextColor3 = State and 'AccentColor' or 'FontColor';

            local YSize = 0
            local XSize = 0

            for _, Label in next, Library.KeybindContainer:GetChildren() do
                if Label:IsA('TextLabel') and Label.Visible then
                    YSize = YSize + 18;
                    if (Label.TextBounds.X > XSize) then
                        XSize = Label.TextBounds.X
                    end
                end;
            end;

            Library.KeybindFrame.Size = UDim2.new(0, math.max(XSize + 10, 210), 0, YSize + 23)
        end;

        function KeyPicker:GetState()
            if KeyPicker.Mode == 'Always' then
                return true;
            elseif KeyPicker.Mode == 'Hold' then
                if KeyPicker.Value == 'None' then
                    return false;
                end

                local Key = KeyPicker.Value;

                if Key == 'MB1' or Key == 'MB2' then
                    return Key == 'MB1' and InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
                        or Key == 'MB2' and InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2);
                else
                    return InputService:IsKeyDown(Enum.KeyCode[KeyPicker.Value]);
                end;
            else
                return KeyPicker.Toggled;
            end;
        end;

        function KeyPicker:SetValue(Data)
            local Key, Mode = Data[1], Data[2];
            DisplayLabel.Text = Key;
            KeyPicker.Value = Key;
            ModeButtons[Mode]:Select();
            KeyPicker:Update();
        end;

        function KeyPicker:OnClick(Callback)
            KeyPicker.Clicked = Callback
        end

        function KeyPicker:OnChanged(Callback)
            KeyPicker.Changed = Callback
            Callback(KeyPicker.Value)
        end

        if ParentObj.Addons then
            table.insert(ParentObj.Addons, KeyPicker)
        end

        function KeyPicker:DoClick()
            if ParentObj.Type == 'Toggle' and KeyPicker.SyncToggleState then
                ParentObj:SetValue(not ParentObj.Value)
            end

            Library:SafeCallback(KeyPicker.Callback, KeyPicker.Toggled)
            Library:SafeCallback(KeyPicker.Clicked, KeyPicker.Toggled)
        end

        local Picking = false;

        PickOuter.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 and not Library:MouseIsOverOpenedFrame() then
                Picking = true;

                DisplayLabel.Text = '';

                local Break;
                local Text = '';

                task.spawn(function()
                    while (not Break) do
                        if Text == '...' then
                            Text = '';
                        end;

                        Text = Text .. '.';
                        DisplayLabel.Text = Text;

                        wait(0.4);
                    end;
                end);

                wait(0.2);

                local Event;
                Event = InputService.InputBegan:Connect(function(Input)
                    local Key;

                    if Input.UserInputType == Enum.UserInputType.Keyboard then
                        Key = Input.KeyCode.Name;
                    elseif Input.UserInputType == Enum.UserInputType.MouseButton1 then
                        Key = 'MB1';
                    elseif Input.UserInputType == Enum.UserInputType.MouseButton2 then
                        Key = 'MB2';
                    end;

                    Break = true;
                    Picking = false;

                    DisplayLabel.Text = Key;
                    KeyPicker.Value = Key;

                    Library:SafeCallback(KeyPicker.ChangedCallback, Input.KeyCode or Input.UserInputType)
                    Library:SafeCallback(KeyPicker.Changed, Input.KeyCode or Input.UserInputType)

                    Library:AttemptSave();

                    Event:Disconnect();
                end);
            elseif Input.UserInputType == Enum.UserInputType.MouseButton2 and not Library:MouseIsOverOpenedFrame() then
                ModeSelectOuter.Visible = true;
            end;
        end);

        Library:GiveSignal(InputService.InputBegan:Connect(function(Input)
            if (not Picking) then
                if KeyPicker.Mode == 'Toggle' then
                    local Key = KeyPicker.Value;

                    if Key == 'MB1' or Key == 'MB2' then
                        if Key == 'MB1' and Input.UserInputType == Enum.UserInputType.MouseButton1
                        or Key == 'MB2' and Input.UserInputType == Enum.UserInputType.MouseButton2 then
                            KeyPicker.Toggled = not KeyPicker.Toggled
                            KeyPicker:DoClick()
                        end;
                    elseif Input.UserInputType == Enum.UserInputType.Keyboard then
                        if Input.KeyCode.Name == Key then
                            KeyPicker.Toggled = not KeyPicker.Toggled;
                            KeyPicker:DoClick()
                        end;
                    end;
                end;

                KeyPicker:Update();
            end;

            if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                local AbsPos, AbsSize = ModeSelectOuter.AbsolutePosition, ModeSelectOuter.AbsoluteSize;

                if Mouse.X < AbsPos.X or Mouse.X > AbsPos.X + AbsSize.X
                    or Mouse.Y < (AbsPos.Y - 20 - 1) or Mouse.Y > AbsPos.Y + AbsSize.Y then

                    ModeSelectOuter.Visible = false;
                end;
            end;
        end))

        Library:GiveSignal(InputService.InputEnded:Connect(function(Input)
            if (not Picking) then
                KeyPicker:Update();
            end;
        end))

        KeyPicker:Update();

        Options[Idx] = KeyPicker;

        return self;
    end;

    BaseAddons.__index = Funcs;
    BaseAddons.__namecall = function(Table, Key, ...)
        return Funcs[Key](...);
    end;
end;

local BaseGroupbox = {};

do
    local Funcs = {};

    function Funcs:AddBlank(Size)
        local Groupbox = self;
        local Container = Groupbox.Container;

        Library:Create('Frame', {
            BackgroundTransparency = 1;
            Size = UDim2.new(1, 0, 0, Size);
            ZIndex = 1;
            Parent = Container;
        });
    end;

    function Funcs:AddLabel(Text, DoesWrap)
        local Label = {};

        local Groupbox = self;
        local Container = Groupbox.Container;

        local TextLabel = Library:CreateLabel({
            Size = UDim2.new(1, -4, 0, 15);
            TextSize = 14;
            Text = Text;
            TextWrapped = DoesWrap or false,
            TextXAlignment = Enum.TextXAlignment.Left;
            ZIndex = 5;
            Parent = Container;
        });

        if DoesWrap then
            local Y = select(2, Library:GetTextBounds(Text, Library.Font, 14, Vector2.new(TextLabel.AbsoluteSize.X, math.huge)))
            TextLabel.Size = UDim2.new(1, -4, 0, Y)
        else
            Library:Create('UIListLayout', {
                Padding = UDim.new(0, 4);
                FillDirection = Enum.FillDirection.Horizontal;
                HorizontalAlignment = Enum.HorizontalAlignment.Right;
                SortOrder = Enum.SortOrder.LayoutOrder;
                Parent = TextLabel;
            });
        end

        Label.TextLabel = TextLabel;
        Label.Container = Container;

        function Label:SetText(Text)
            TextLabel.Text = Text

            if DoesWrap then
                local Y = select(2, Library:GetTextBounds(Text, Library.Font, 14, Vector2.new(TextLabel.AbsoluteSize.X, math.huge)))
                TextLabel.Size = UDim2.new(1, -4, 0, Y)
            end

            Groupbox:Resize();
        end

        if (not DoesWrap) then
            setmetatable(Label, BaseAddons);
        end

        Groupbox:AddBlank(5);
        Groupbox:Resize();

        return Label;
    end;

    function Funcs:AddButton(...)
        -- TODO: Eventually redo this
        local Button = {};
        local function ProcessButtonParams(Class, Obj, ...)
            local Props = select(1, ...)
            if type(Props) == 'table' then
                Obj.Text = Props.Text
                Obj.Func = Props.Func
                Obj.DoubleClick = Props.DoubleClick
                Obj.Tooltip = Props.Tooltip
            else
                Obj.Text = select(1, ...)
                Obj.Func = select(2, ...)
            end

            assert(type(Obj.Func) == 'function', 'AddButton: `Func` callback is missing.');
        end

        ProcessButtonParams('Button', Button, ...)

        local Groupbox = self;
        local Container = Groupbox.Container;

        local function CreateBaseButton(Button)
            local Outer = Library:Create('Frame', {
                BackgroundColor3 = Color3.new(0, 0, 0);
                BorderColor3 = Color3.new(0, 0, 0);
                Size = UDim2.new(1, -4, 0, 20);
                ZIndex = 5;
            });

            local Inner = Library:Create('Frame', {
                BackgroundColor3 = Library.MainColor;
                BorderColor3 = Library.OutlineColor;
                BorderMode = Enum.BorderMode.Inset;
                Size = UDim2.new(1, 0, 1, 0);
                ZIndex = 6;
                Parent = Outer;
            });

            local Label = Library:CreateLabel({
                Size = UDim2.new(1, 0, 1, 0);
                TextSize = 14;
                Text = Button.Text;
                ZIndex = 6;
                Parent = Inner;
            });

            Library:Create('UIGradient', {
                Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(212, 212, 212))
                });
                Rotation = 90;
                Parent = Inner;
            });

            Library:AddToRegistry(Outer, {
                BorderColor3 = 'Black';
            });

            Library:AddToRegistry(Inner, {
                BackgroundColor3 = 'MainColor';
                BorderColor3 = 'OutlineColor';
            });

            Library:OnHighlight(Outer, Outer,
                { BorderColor3 = 'AccentColor' },
                { BorderColor3 = 'Black' }
            );

            return Outer, Inner, Label
        end

        local function InitEvents(Button)
            local function WaitForEvent(event, timeout, validator)
                local bindable = Instance.new('BindableEvent')
                local connection = event:Once(function(...)

                    if type(validator) == 'function' and validator(...) then
                        bindable:Fire(true)
                    else
                        bindable:Fire(false)
                    end
                end)
                task.delay(timeout, function()
                    connection:disconnect()
                    bindable:Fire(false)
                end)
                return bindable.Event:Wait()
            end

            local function ValidateClick(Input)
                if Library:MouseIsOverOpenedFrame() then
                    return false
                end

                if Input.UserInputType ~= Enum.UserInputType.MouseButton1 then
                    return false
                end

                return true
            end

            Button.Outer.InputBegan:Connect(function(Input)
                if not ValidateClick(Input) then return end
                if Button.Locked then return end

                if Button.DoubleClick then
                    Library:RemoveFromRegistry(Button.Label)
                    Library:AddToRegistry(Button.Label, { TextColor3 = 'AccentColor' })

                    Button.Label.TextColor3 = Library.AccentColor
                    Button.Label.Text = 'Are you sure?'
                    Button.Locked = true

                    local clicked = WaitForEvent(Button.Outer.InputBegan, 0.5, ValidateClick)

                    Library:RemoveFromRegistry(Button.Label)
                    Library:AddToRegistry(Button.Label, { TextColor3 = 'FontColor' })

                    Button.Label.TextColor3 = Library.FontColor
                    Button.Label.Text = Button.Text
                    task.defer(rawset, Button, 'Locked', false)

                    if clicked then
                        Library:SafeCallback(Button.Func)
                    end

                    return
                end

                Library:SafeCallback(Button.Func);
            end)
        end

        Button.Outer, Button.Inner, Button.Label = CreateBaseButton(Button)
        Button.Outer.Parent = Container

        InitEvents(Button)

        function Button:AddTooltip(tooltip)
            if type(tooltip) == 'string' then
                Library:AddToolTip(tooltip, self.Outer)
            end
            return self
        end


        function Button:AddButton(...)
            local SubButton = {}

            ProcessButtonParams('SubButton', SubButton, ...)

            self.Outer.Size = UDim2.new(0.5, -2, 0, 20)

            SubButton.Outer, SubButton.Inner, SubButton.Label = CreateBaseButton(SubButton)

            SubButton.Outer.Position = UDim2.new(1, 3, 0, 0)
            SubButton.Outer.Size = UDim2.fromOffset(self.Outer.AbsoluteSize.X - 2, self.Outer.AbsoluteSize.Y)
            SubButton.Outer.Parent = self.Outer

            function SubButton:AddTooltip(tooltip)
                if type(tooltip) == 'string' then
                    Library:AddToolTip(tooltip, self.Outer)
                end
                return SubButton
            end

            if type(SubButton.Tooltip) == 'string' then
                SubButton:AddTooltip(SubButton.Tooltip)
            end

            InitEvents(SubButton)
            return SubButton
        end

        if type(Button.Tooltip) == 'string' then
            Button:AddTooltip(Button.Tooltip)
        end

        Groupbox:AddBlank(5);
        Groupbox:Resize();

        return Button;
    end;

    function Funcs:AddDivider()
        local Groupbox = self;
        local Container = self.Container

        local Divider = {
            Type = 'Divider',
        }

        Groupbox:AddBlank(2);
        local DividerOuter = Library:Create('Frame', {
            BackgroundColor3 = Color3.new(0, 0, 0);
            BorderColor3 = Color3.new(0, 0, 0);
            Size = UDim2.new(1, -4, 0, 5);
            ZIndex = 5;
            Parent = Container;
        });

        local DividerInner = Library:Create('Frame', {
            BackgroundColor3 = Library.MainColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 6;
            Parent = DividerOuter;
        });

        Library:AddToRegistry(DividerOuter, {
            BorderColor3 = 'Black';
        });

        Library:AddToRegistry(DividerInner, {
            BackgroundColor3 = 'MainColor';
            BorderColor3 = 'OutlineColor';
        });

        Groupbox:AddBlank(9);
        Groupbox:Resize();
    end

    function Funcs:AddInput(Idx, Info)
        assert(Info.Text, 'AddInput: Missing `Text` string.')

        local Textbox = {
            Value = Info.Default or '';
            Numeric = Info.Numeric or false;
            Finished = Info.Finished or false;
            Type = 'Input';
            Callback = Info.Callback or function(Value) end;
        };

        local Groupbox = self;
        local Container = Groupbox.Container;

        local InputLabel = Library:CreateLabel({
            Size = UDim2.new(1, 0, 0, 15);
            TextSize = 14;
            Text = Info.Text;
            TextXAlignment = Enum.TextXAlignment.Left;
            ZIndex = 5;
            Parent = Container;
        });

        Groupbox:AddBlank(1);

        local TextBoxOuter = Library:Create('Frame', {
            BackgroundColor3 = Color3.new(0, 0, 0);
            BorderColor3 = Color3.new(0, 0, 0);
            Size = UDim2.new(1, -4, 0, 20);
            ZIndex = 5;
            Parent = Container;
        });

        local TextBoxInner = Library:Create('Frame', {
            BackgroundColor3 = Library.MainColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 6;
            Parent = TextBoxOuter;
        });

        Library:AddToRegistry(TextBoxInner, {
            BackgroundColor3 = 'MainColor';
            BorderColor3 = 'OutlineColor';
        });

        Library:OnHighlight(TextBoxOuter, TextBoxOuter,
            { BorderColor3 = 'AccentColor' },
            { BorderColor3 = 'Black' }
        );

        if type(Info.Tooltip) == 'string' then
            Library:AddToolTip(Info.Tooltip, TextBoxOuter)
        end

        Library:Create('UIGradient', {
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(212, 212, 212))
            });
            Rotation = 90;
            Parent = TextBoxInner;
        });

        local Container = Library:Create('Frame', {
            BackgroundTransparency = 1;
            ClipsDescendants = true;

            Position = UDim2.new(0, 5, 0, 0);
            Size = UDim2.new(1, -5, 1, 0);

            ZIndex = 7;
            Parent = TextBoxInner;
        })

        local Box = Library:Create('TextBox', {
            BackgroundTransparency = 1;

            Position = UDim2.fromOffset(0, 0),
            Size = UDim2.fromScale(5, 1),

            Font = Library.Font;
            PlaceholderColor3 = Color3.fromRGB(190, 190, 190);
            PlaceholderText = Info.Placeholder or '';

            Text = Info.Default or '';
            TextColor3 = Library.FontColor;
            TextSize = 14;
            TextStrokeTransparency = 0;
            TextXAlignment = Enum.TextXAlignment.Left;

            ZIndex = 7;
            Parent = Container;
        });

        Library:ApplyTextStroke(Box);

        function Textbox:SetValue(Text)
            if Info.MaxLength and #Text > Info.MaxLength then
                Text = Text:sub(1, Info.MaxLength);
            end;

            if Textbox.Numeric then
                if (not tonumber(Text)) and Text:len() > 0 then
                    Text = Textbox.Value
                end
            end

            Textbox.Value = Text;
            Box.Text = Text;

            Library:SafeCallback(Textbox.Callback, Textbox.Value);
            Library:SafeCallback(Textbox.Changed, Textbox.Value);
        end;

        if Textbox.Finished then
            Box.FocusLost:Connect(function(enter)
                if not enter then return end

                Textbox:SetValue(Box.Text);
                Library:AttemptSave();
            end)
        else
            Box:GetPropertyChangedSignal('Text'):Connect(function()
                Textbox:SetValue(Box.Text);
                Library:AttemptSave();
            end);
        end

        -- https://devforum.roblox.com/t/how-to-make-textboxes-follow-current-cursor-position/1368429/6
        -- thank you nicemike40 :)

        local function Update()
            local PADDING = 2
            local reveal = Container.AbsoluteSize.X

            if not Box:IsFocused() or Box.TextBounds.X <= reveal - 2 * PADDING then
                -- we aren't focused, or we fit so be normal
                Box.Position = UDim2.new(0, PADDING, 0, 0)
            else
                -- we are focused and don't fit, so adjust position
                local cursor = Box.CursorPosition
                if cursor ~= -1 then
                    -- calculate pixel width of text from start to cursor
                    local subtext = string.sub(Box.Text, 1, cursor-1)
                    local width = TextService:GetTextSize(subtext, Box.TextSize, Box.Font, Vector2.new(math.huge, math.huge)).X

                    -- check if we're inside the box with the cursor
                    local currentCursorPos = Box.Position.X.Offset + width

                    -- adjust if necessary
                    if currentCursorPos < PADDING then
                        Box.Position = UDim2.fromOffset(PADDING-width, 0)
                    elseif currentCursorPos > reveal - PADDING - 1 then
                        Box.Position = UDim2.fromOffset(reveal-width-PADDING-1, 0)
                    end
                end
            end
        end

        task.spawn(Update)

        Box:GetPropertyChangedSignal('Text'):Connect(Update)
        Box:GetPropertyChangedSignal('CursorPosition'):Connect(Update)
        Box.FocusLost:Connect(Update)
        Box.Focused:Connect(Update)

        Library:AddToRegistry(Box, {
            TextColor3 = 'FontColor';
        });

        function Textbox:OnChanged(Func)
            Textbox.Changed = Func;
            Func(Textbox.Value);
        end;

        Groupbox:AddBlank(5);
        Groupbox:Resize();

        Options[Idx] = Textbox;

        return Textbox;
    end;

    function Funcs:AddToggle(Idx, Info)
        assert(Info.Text, 'AddInput: Missing `Text` string.')

        local Toggle = {
            Value = Info.Default or false;
            Type = 'Toggle';

            Callback = Info.Callback or function(Value) end;
            Addons = {},
            Risky = Info.Risky,
        };

        local Groupbox = self;
        local Container = Groupbox.Container;

        local ToggleOuter = Library:Create('Frame', {
            BackgroundColor3 = Color3.new(0, 0, 0);
            BorderColor3 = Color3.new(0, 0, 0);
            Size = UDim2.new(0, 13, 0, 13);
            ZIndex = 5;
            Parent = Container;
        });

        Library:AddToRegistry(ToggleOuter, {
            BorderColor3 = 'Black';
        });

        local ToggleInner = Library:Create('Frame', {
            BackgroundColor3 = Library.MainColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 6;
            Parent = ToggleOuter;
        });

        Library:AddToRegistry(ToggleInner, {
            BackgroundColor3 = 'MainColor';
            BorderColor3 = 'OutlineColor';
        });

        local ToggleLabel = Library:CreateLabel({
            Size = UDim2.new(0, 216, 1, 0);
            Position = UDim2.new(1, 6, 0, 0);
            TextSize = 14;
            Text = Info.Text;
            TextXAlignment = Enum.TextXAlignment.Left;
            ZIndex = 6;
            Parent = ToggleInner;
        });

        Library:Create('UIListLayout', {
            Padding = UDim.new(0, 4);
            FillDirection = Enum.FillDirection.Horizontal;
            HorizontalAlignment = Enum.HorizontalAlignment.Right;
            SortOrder = Enum.SortOrder.LayoutOrder;
            Parent = ToggleLabel;
        });

        local ToggleRegion = Library:Create('Frame', {
            BackgroundTransparency = 1;
            Size = UDim2.new(0, 170, 1, 0);
            ZIndex = 8;
            Parent = ToggleOuter;
        });

        Library:OnHighlight(ToggleRegion, ToggleOuter,
            { BorderColor3 = 'AccentColor' },
            { BorderColor3 = 'Black' }
        );

        function Toggle:UpdateColors()
            Toggle:Display();
        end;

        if type(Info.Tooltip) == 'string' then
            Library:AddToolTip(Info.Tooltip, ToggleRegion)
        end

        function Toggle:Display()
            ToggleInner.BackgroundColor3 = Toggle.Value and Library.AccentColor or Library.MainColor;
            ToggleInner.BorderColor3 = Toggle.Value and Library.AccentColorDark or Library.OutlineColor;

            Library.RegistryMap[ToggleInner].Properties.BackgroundColor3 = Toggle.Value and 'AccentColor' or 'MainColor';
            Library.RegistryMap[ToggleInner].Properties.BorderColor3 = Toggle.Value and 'AccentColorDark' or 'OutlineColor';
        end;

        function Toggle:OnChanged(Func)
            Toggle.Changed = Func;
            Func(Toggle.Value);
        end;

        function Toggle:SetValue(Bool)
            Bool = (not not Bool);

            Toggle.Value = Bool;
            Toggle:Display();

            for _, Addon in next, Toggle.Addons do
                if Addon.Type == 'KeyPicker' and Addon.SyncToggleState then
                    Addon.Toggled = Bool
                    Addon:Update()
                end
            end

            Library:SafeCallback(Toggle.Callback, Toggle.Value);
            Library:SafeCallback(Toggle.Changed, Toggle.Value);
            Library:UpdateDependencyBoxes();
        end;

        ToggleRegion.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 and not Library:MouseIsOverOpenedFrame() then
                Toggle:SetValue(not Toggle.Value) -- Why was it not like this from the start?
                Library:AttemptSave();
            end;
        end);

        if Toggle.Risky then
            Library:RemoveFromRegistry(ToggleLabel)
            ToggleLabel.TextColor3 = Library.RiskColor
            Library:AddToRegistry(ToggleLabel, { TextColor3 = 'RiskColor' })
        end

        Toggle:Display();
        Groupbox:AddBlank(Info.BlankSize or 5 + 2);
        Groupbox:Resize();

        Toggle.TextLabel = ToggleLabel;
        Toggle.Container = Container;
        setmetatable(Toggle, BaseAddons);

        Toggles[Idx] = Toggle;

        Library:UpdateDependencyBoxes();

        return Toggle;
    end;

    function Funcs:AddSlider(Idx, Info)
        assert(Info.Default, 'AddSlider: Missing default value.');
        assert(Info.Text, 'AddSlider: Missing slider text.');
        assert(Info.Min, 'AddSlider: Missing minimum value.');
        assert(Info.Max, 'AddSlider: Missing maximum value.');
        assert(Info.Rounding, 'AddSlider: Missing rounding value.');

        local Slider = {
            Value = Info.Default;
            Min = Info.Min;
            Max = Info.Max;
            Rounding = Info.Rounding;
            MaxSize = 232;
            Type = 'Slider';
            Callback = Info.Callback or function(Value) end;
        };

        local Groupbox = self;
        local Container = Groupbox.Container;

        if not Info.Compact then
            Library:CreateLabel({
                Size = UDim2.new(1, 0, 0, 10);
                TextSize = 14;
                Text = Info.Text;
                TextXAlignment = Enum.TextXAlignment.Left;
                TextYAlignment = Enum.TextYAlignment.Bottom;
                ZIndex = 5;
                Parent = Container;
            });

            Groupbox:AddBlank(3);
        end

        local SliderOuter = Library:Create('Frame', {
            BackgroundColor3 = Color3.new(0, 0, 0);
            BorderColor3 = Color3.new(0, 0, 0);
            Size = UDim2.new(1, -4, 0, 13);
            ZIndex = 5;
            Parent = Container;
        });

        Library:AddToRegistry(SliderOuter, {
            BorderColor3 = 'Black';
        });

        local SliderInner = Library:Create('Frame', {
            BackgroundColor3 = Library.MainColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 6;
            Parent = SliderOuter;
        });

        Library:AddToRegistry(SliderInner, {
            BackgroundColor3 = 'MainColor';
            BorderColor3 = 'OutlineColor';
        });

        local Fill = Library:Create('Frame', {
            BackgroundColor3 = Library.AccentColor;
            BorderColor3 = Library.AccentColorDark;
            Size = UDim2.new(0, 0, 1, 0);
            ZIndex = 7;
            Parent = SliderInner;
        });

        Library:AddToRegistry(Fill, {
            BackgroundColor3 = 'AccentColor';
            BorderColor3 = 'AccentColorDark';
        });

        local HideBorderRight = Library:Create('Frame', {
            BackgroundColor3 = Library.AccentColor;
            BorderSizePixel = 0;
            Position = UDim2.new(1, 0, 0, 0);
            Size = UDim2.new(0, 1, 1, 0);
            ZIndex = 8;
            Parent = Fill;
        });

        Library:AddToRegistry(HideBorderRight, {
            BackgroundColor3 = 'AccentColor';
        });

        local DisplayLabel = Library:CreateLabel({
            Size = UDim2.new(1, 0, 1, 0);
            TextSize = 14;
            Text = 'Infinite';
            ZIndex = 9;
            Parent = SliderInner;
        });

        Library:OnHighlight(SliderOuter, SliderOuter,
            { BorderColor3 = 'AccentColor' },
            { BorderColor3 = 'Black' }
        );

        if type(Info.Tooltip) == 'string' then
            Library:AddToolTip(Info.Tooltip, SliderOuter)
        end

        function Slider:UpdateColors()
            Fill.BackgroundColor3 = Library.AccentColor;
            Fill.BorderColor3 = Library.AccentColorDark;
        end;

        function Slider:Display()
            local Suffix = Info.Suffix or '';

            if Info.Compact then
                DisplayLabel.Text = Info.Text .. ': ' .. Slider.Value .. Suffix
            elseif Info.HideMax then
                DisplayLabel.Text = string.format('%s', Slider.Value .. Suffix)
            else
                DisplayLabel.Text = string.format('%s/%s', Slider.Value .. Suffix, Slider.Max .. Suffix);
            end

            local X = math.ceil(Library:MapValue(Slider.Value, Slider.Min, Slider.Max, 0, Slider.MaxSize));
            Fill.Size = UDim2.new(0, X, 1, 0);

            HideBorderRight.Visible = not (X == Slider.MaxSize or X == 0);
        end;

        function Slider:OnChanged(Func)
            Slider.Changed = Func;
            Func(Slider.Value);
        end;

        local function Round(Value)
            if Slider.Rounding == 0 then
                return math.floor(Value);
            end;


            return tonumber(string.format('%.' .. Slider.Rounding .. 'f', Value))
        end;

        function Slider:GetValueFromXOffset(X)
            return Round(Library:MapValue(X, 0, Slider.MaxSize, Slider.Min, Slider.Max));
        end;

        function Slider:SetValue(Str)
            local Num = tonumber(Str);

            if (not Num) then
                return;
            end;

            Num = math.clamp(Num, Slider.Min, Slider.Max);

            Slider.Value = Num;
            Slider:Display();

            Library:SafeCallback(Slider.Callback, Slider.Value);
            Library:SafeCallback(Slider.Changed, Slider.Value);
        end;

        SliderInner.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 and not Library:MouseIsOverOpenedFrame() then
                local mPos = Mouse.X;
                local gPos = Fill.Size.X.Offset;
                local Diff = mPos - (Fill.AbsolutePosition.X + gPos);

                while InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
                    local nMPos = Mouse.X;
                    local nX = math.clamp(gPos + (nMPos - mPos) + Diff, 0, Slider.MaxSize);

                    local nValue = Slider:GetValueFromXOffset(nX);
                    local OldValue = Slider.Value;
                    Slider.Value = nValue;

                    Slider:Display();

                    if nValue ~= OldValue then
                        Library:SafeCallback(Slider.Callback, Slider.Value);
                        Library:SafeCallback(Slider.Changed, Slider.Value);
                    end;

                    RenderStepped:Wait();
                end;

                Library:AttemptSave();
            end;
        end);

        Slider:Display();
        Groupbox:AddBlank(Info.BlankSize or 6);
        Groupbox:Resize();

        Options[Idx] = Slider;

        return Slider;
    end;

    function Funcs:AddDropdown(Idx, Info)
        if Info.SpecialType == 'Player' then
            Info.Values = GetPlayersString();
            Info.AllowNull = true;
        elseif Info.SpecialType == 'Team' then
            Info.Values = GetTeamsString();
            Info.AllowNull = true;
        end;

        assert(Info.Values, 'AddDropdown: Missing dropdown value list.');
        assert(Info.AllowNull or Info.Default, 'AddDropdown: Missing default value. Pass `AllowNull` as true if this was intentional.')

        if (not Info.Text) then
            Info.Compact = true;
        end;

        local Dropdown = {
            Values = Info.Values;
            Value = Info.Multi and {};
            Multi = Info.Multi;
            Type = 'Dropdown';
            SpecialType = Info.SpecialType; -- can be either 'Player' or 'Team'
            Callback = Info.Callback or function(Value) end;
        };

        local Groupbox = self;
        local Container = Groupbox.Container;

        local RelativeOffset = 0;

        if not Info.Compact then
            local DropdownLabel = Library:CreateLabel({
                Size = UDim2.new(1, 0, 0, 10);
                TextSize = 14;
                Text = Info.Text;
                TextXAlignment = Enum.TextXAlignment.Left;
                TextYAlignment = Enum.TextYAlignment.Bottom;
                ZIndex = 5;
                Parent = Container;
            });

            Groupbox:AddBlank(3);
        end

        for _, Element in next, Container:GetChildren() do
            if not Element:IsA('UIListLayout') then
                RelativeOffset = RelativeOffset + Element.Size.Y.Offset;
            end;
        end;

        local DropdownOuter = Library:Create('Frame', {
            BackgroundColor3 = Color3.new(0, 0, 0);
            BorderColor3 = Color3.new(0, 0, 0);
            Size = UDim2.new(1, -4, 0, 20);
            ZIndex = 5;
            Parent = Container;
        });

        Library:AddToRegistry(DropdownOuter, {
            BorderColor3 = 'Black';
        });

        local DropdownInner = Library:Create('Frame', {
            BackgroundColor3 = Library.MainColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 6;
            Parent = DropdownOuter;
        });

        Library:AddToRegistry(DropdownInner, {
            BackgroundColor3 = 'MainColor';
            BorderColor3 = 'OutlineColor';
        });

        Library:Create('UIGradient', {
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(212, 212, 212))
            });
            Rotation = 90;
            Parent = DropdownInner;
        });

        local DropdownArrow = Library:Create('ImageLabel', {
            AnchorPoint = Vector2.new(0, 0.5);
            BackgroundTransparency = 1;
            Position = UDim2.new(1, -16, 0.5, 0);
            Size = UDim2.new(0, 12, 0, 12);
            Image = 'http://www.roblox.com/asset/?id=6282522798';
            ZIndex = 8;
            Parent = DropdownInner;
        });

        local ItemList = Library:CreateLabel({
            Position = UDim2.new(0, 5, 0, 0);
            Size = UDim2.new(1, -5, 1, 0);
            TextSize = 14;
            Text = '--';
            TextXAlignment = Enum.TextXAlignment.Left;
            TextWrapped = true;
            ZIndex = 7;
            Parent = DropdownInner;
        });

        Library:OnHighlight(DropdownOuter, DropdownOuter,
            { BorderColor3 = 'AccentColor' },
            { BorderColor3 = 'Black' }
        );

        if type(Info.Tooltip) == 'string' then
            Library:AddToolTip(Info.Tooltip, DropdownOuter)
        end

        local MAX_DROPDOWN_ITEMS = 8;

        local ListOuter = Library:Create('Frame', {
            BackgroundColor3 = Color3.new(0, 0, 0);
            BorderColor3 = Color3.new(0, 0, 0);
            ZIndex = 20;
            Visible = false;
            Parent = ScreenGui;
        });

        local function RecalculateListPosition()
            ListOuter.Position = UDim2.fromOffset(DropdownOuter.AbsolutePosition.X, DropdownOuter.AbsolutePosition.Y + DropdownOuter.Size.Y.Offset + 1);
        end;

        local function RecalculateListSize(YSize)
            ListOuter.Size = UDim2.fromOffset(DropdownOuter.AbsoluteSize.X, YSize or (MAX_DROPDOWN_ITEMS * 20 + 2))
        end;

        RecalculateListPosition();
        RecalculateListSize();

        DropdownOuter:GetPropertyChangedSignal('AbsolutePosition'):Connect(RecalculateListPosition);

        local ListInner = Library:Create('Frame', {
            BackgroundColor3 = Library.MainColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            BorderSizePixel = 0;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 21;
            Parent = ListOuter;
        });

        Library:AddToRegistry(ListInner, {
            BackgroundColor3 = 'MainColor';
            BorderColor3 = 'OutlineColor';
        });

        local Scrolling = Library:Create('ScrollingFrame', {
            BackgroundTransparency = 1;
            BorderSizePixel = 0;
            CanvasSize = UDim2.new(0, 0, 0, 0);
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 21;
            Parent = ListInner;

            TopImage = 'rbxasset://textures/ui/Scroll/scroll-middle.png',
            BottomImage = 'rbxasset://textures/ui/Scroll/scroll-middle.png',

            ScrollBarThickness = 3,
            ScrollBarImageColor3 = Library.AccentColor,
        });

        Library:AddToRegistry(Scrolling, {
            ScrollBarImageColor3 = 'AccentColor'
        })

        Library:Create('UIListLayout', {
            Padding = UDim.new(0, 0);
            FillDirection = Enum.FillDirection.Vertical;
            SortOrder = Enum.SortOrder.LayoutOrder;
            Parent = Scrolling;
        });

        function Dropdown:Display()
            local Values = Dropdown.Values;
            local Str = '';

            if Info.Multi then
                for Idx, Value in next, Values do
                    if Dropdown.Value[Value] then
                        Str = Str .. Value .. ', ';
                    end;
                end;

                Str = Str:sub(1, #Str - 2);
            else
                Str = Dropdown.Value or '';
            end;

            ItemList.Text = (Str == '' and '--' or Str);
        end;

        function Dropdown:GetActiveValues()
            if Info.Multi then
                local T = {};

                for Value, Bool in next, Dropdown.Value do
                    table.insert(T, Value);
                end;

                return T;
            else
                return Dropdown.Value and 1 or 0;
            end;
        end;

        function Dropdown:BuildDropdownList()
            local Values = Dropdown.Values;
            local Buttons = {};

            for _, Element in next, Scrolling:GetChildren() do
                if not Element:IsA('UIListLayout') then
                    Element:Destroy();
                end;
            end;

            local Count = 0;

            for Idx, Value in next, Values do
                local Table = {};

                Count = Count + 1;

                local Button = Library:Create('Frame', {
                    BackgroundColor3 = Library.MainColor;
                    BorderColor3 = Library.OutlineColor;
                    BorderMode = Enum.BorderMode.Middle;
                    Size = UDim2.new(1, -1, 0, 20);
                    ZIndex = 23;
                    Active = true,
                    Parent = Scrolling;
                });

                Library:AddToRegistry(Button, {
                    BackgroundColor3 = 'MainColor';
                    BorderColor3 = 'OutlineColor';
                });

                local ButtonLabel = Library:CreateLabel({
                    Active = false;
                    Size = UDim2.new(1, -6, 1, 0);
                    Position = UDim2.new(0, 6, 0, 0);
                    TextSize = 14;
                    Text = Value;
                    TextXAlignment = Enum.TextXAlignment.Left;
                    ZIndex = 25;
                    Parent = Button;
                });

                Library:OnHighlight(Button, Button,
                    { BorderColor3 = 'AccentColor', ZIndex = 24 },
                    { BorderColor3 = 'OutlineColor', ZIndex = 23 }
                );

                local Selected;

                if Info.Multi then
                    Selected = Dropdown.Value[Value];
                else
                    Selected = Dropdown.Value == Value;
                end;

                function Table:UpdateButton()
                    if Info.Multi then
                        Selected = Dropdown.Value[Value];
                    else
                        Selected = Dropdown.Value == Value;
                    end;

                    ButtonLabel.TextColor3 = Selected and Library.AccentColor or Library.FontColor;
                    Library.RegistryMap[ButtonLabel].Properties.TextColor3 = Selected and 'AccentColor' or 'FontColor';
                end;

                ButtonLabel.InputBegan:Connect(function(Input)
                    if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                        local Try = not Selected;

                        if Dropdown:GetActiveValues() == 1 and (not Try) and (not Info.AllowNull) then
                        else
                            if Info.Multi then
                                Selected = Try;

                                if Selected then
                                    Dropdown.Value[Value] = true;
                                else
                                    Dropdown.Value[Value] = nil;
                                end;
                            else
                                Selected = Try;

                                if Selected then
                                    Dropdown.Value = Value;
                                else
                                    Dropdown.Value = nil;
                                end;

                                for _, OtherButton in next, Buttons do
                                    OtherButton:UpdateButton();
                                end;
                            end;

                            Table:UpdateButton();
                            Dropdown:Display();

                            Library:SafeCallback(Dropdown.Callback, Dropdown.Value);
                            Library:SafeCallback(Dropdown.Changed, Dropdown.Value);

                            Library:AttemptSave();
                        end;
                    end;
                end);

                Table:UpdateButton();
                Dropdown:Display();

                Buttons[Button] = Table;
            end;

            Scrolling.CanvasSize = UDim2.fromOffset(0, (Count * 20) + 1);

            local Y = math.clamp(Count * 20, 0, MAX_DROPDOWN_ITEMS * 20) + 1;
            RecalculateListSize(Y);
        end;

        function Dropdown:SetValues(NewValues)
            if NewValues then
                Dropdown.Values = NewValues;
            end;

            Dropdown:BuildDropdownList();
        end;

        function Dropdown:OpenDropdown()
            ListOuter.Visible = true;
            Library.OpenedFrames[ListOuter] = true;
            DropdownArrow.Rotation = 180;
        end;

        function Dropdown:CloseDropdown()
            ListOuter.Visible = false;
            Library.OpenedFrames[ListOuter] = nil;
            DropdownArrow.Rotation = 0;
        end;

        function Dropdown:OnChanged(Func)
            Dropdown.Changed = Func;
            Func(Dropdown.Value);
        end;

        function Dropdown:SetValue(Val)
            if Dropdown.Multi then
                local nTable = {};

                for Value, Bool in next, Val do
                    if table.find(Dropdown.Values, Value) then
                        nTable[Value] = true
                    end;
                end;

                Dropdown.Value = nTable;
            else
                if (not Val) then
                    Dropdown.Value = nil;
                elseif table.find(Dropdown.Values, Val) then
                    Dropdown.Value = Val;
                end;
            end;

            Dropdown:BuildDropdownList();

            Library:SafeCallback(Dropdown.Callback, Dropdown.Value);
            Library:SafeCallback(Dropdown.Changed, Dropdown.Value);
        end;

        DropdownOuter.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 and not Library:MouseIsOverOpenedFrame() then
                if ListOuter.Visible then
                    Dropdown:CloseDropdown();
                else
                    Dropdown:OpenDropdown();
                end;
            end;
        end);

        InputService.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                local AbsPos, AbsSize = ListOuter.AbsolutePosition, ListOuter.AbsoluteSize;

                if Mouse.X < AbsPos.X or Mouse.X > AbsPos.X + AbsSize.X
                    or Mouse.Y < (AbsPos.Y - 20 - 1) or Mouse.Y > AbsPos.Y + AbsSize.Y then

                    Dropdown:CloseDropdown();
                end;
            end;
        end);

        Dropdown:BuildDropdownList();
        Dropdown:Display();

        local Defaults = {}

        if type(Info.Default) == 'string' then
            local Idx = table.find(Dropdown.Values, Info.Default)
            if Idx then
                table.insert(Defaults, Idx)
            end
        elseif type(Info.Default) == 'table' then
            for _, Value in next, Info.Default do
                local Idx = table.find(Dropdown.Values, Value)
                if Idx then
                    table.insert(Defaults, Idx)
                end
            end
        elseif type(Info.Default) == 'number' and Dropdown.Values[Info.Default] ~= nil then
            table.insert(Defaults, Info.Default)
        end

        if next(Defaults) then
            for i = 1, #Defaults do
                local Index = Defaults[i]
                if Info.Multi then
                    Dropdown.Value[Dropdown.Values[Index]] = true
                else
                    Dropdown.Value = Dropdown.Values[Index];
                end

                if (not Info.Multi) then break end
            end

            Dropdown:BuildDropdownList();
            Dropdown:Display();
        end

        Groupbox:AddBlank(Info.BlankSize or 5);
        Groupbox:Resize();

        Options[Idx] = Dropdown;

        return Dropdown;
    end;

    function Funcs:AddDependencyBox()
        local Depbox = {
            Dependencies = {};
        };
        
        local Groupbox = self;
        local Container = Groupbox.Container;

        local Holder = Library:Create('Frame', {
            BackgroundTransparency = 1;
            Size = UDim2.new(1, 0, 0, 0);
            Visible = false;
            Parent = Container;
        });

        local Frame = Library:Create('Frame', {
            BackgroundTransparency = 1;
            Size = UDim2.new(1, 0, 1, 0);
            Visible = true;
            Parent = Holder;
        });

        local Layout = Library:Create('UIListLayout', {
            FillDirection = Enum.FillDirection.Vertical;
            SortOrder = Enum.SortOrder.LayoutOrder;
            Parent = Frame;
        });

        function Depbox:Resize()
            Holder.Size = UDim2.new(1, 0, 0, Layout.AbsoluteContentSize.Y);
            Groupbox:Resize();
        end;

        Layout:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
            Depbox:Resize();
        end);

        Holder:GetPropertyChangedSignal('Visible'):Connect(function()
            Depbox:Resize();
        end);

        function Depbox:Update()
            for _, Dependency in next, Depbox.Dependencies do
                local Elem = Dependency[1];
                local Value = Dependency[2];

                if Elem.Type == 'Toggle' and Elem.Value ~= Value then
                    Holder.Visible = false;
                    Depbox:Resize();
                    return;
                end;
            end;

            Holder.Visible = true;
            Depbox:Resize();
        end;

        function Depbox:SetupDependencies(Dependencies)
            for _, Dependency in next, Dependencies do
                assert(type(Dependency) == 'table', 'SetupDependencies: Dependency is not of type `table`.');
                assert(Dependency[1], 'SetupDependencies: Dependency is missing element argument.');
                assert(Dependency[2] ~= nil, 'SetupDependencies: Dependency is missing value argument.');
            end;

            Depbox.Dependencies = Dependencies;
            Depbox:Update();
        end;

        Depbox.Container = Frame;

        setmetatable(Depbox, BaseGroupbox);

        table.insert(Library.DependencyBoxes, Depbox);

        return Depbox;
    end;

    BaseGroupbox.__index = Funcs;
    BaseGroupbox.__namecall = function(Table, Key, ...)
        return Funcs[Key](...);
    end;
end;

-- < Create other UI elements >
do
    Library.NotificationArea = Library:Create('Frame', {
        BackgroundTransparency = 1;
        Position = UDim2.new(0, 0, 0, 40);
        Size = UDim2.new(0, 300, 0, 200);
        ZIndex = 100;
        Parent = ScreenGui;
    });

    Library:Create('UIListLayout', {
        Padding = UDim.new(0, 4);
        FillDirection = Enum.FillDirection.Vertical;
        SortOrder = Enum.SortOrder.LayoutOrder;
        Parent = Library.NotificationArea;
    });

    local WatermarkOuter = Library:Create('Frame', {
        BorderColor3 = Color3.new(0, 0, 0);
        Position = UDim2.new(0, 100, 0, -25);
        Size = UDim2.new(0, 213, 0, 20);
        ZIndex = 200;
        Visible = false;
        Parent = ScreenGui;
    });

    local WatermarkInner = Library:Create('Frame', {
        BackgroundColor3 = Library.MainColor;
        BorderColor3 = Library.AccentColor;
        BorderMode = Enum.BorderMode.Inset;
        Size = UDim2.new(1, 0, 1, 0);
        ZIndex = 201;
        Parent = WatermarkOuter;
    });

    Library:AddToRegistry(WatermarkInner, {
        BorderColor3 = 'AccentColor';
    });

    local InnerFrame = Library:Create('Frame', {
        BackgroundColor3 = Color3.new(1, 1, 1);
        BorderSizePixel = 0;
        Position = UDim2.new(0, 1, 0, 1);
        Size = UDim2.new(1, -2, 1, -2);
        ZIndex = 202;
        Parent = WatermarkInner;
    });

    local Gradient = Library:Create('UIGradient', {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Library:GetDarkerColor(Library.MainColor)),
            ColorSequenceKeypoint.new(1, Library.MainColor),
        });
        Rotation = -90;
        Parent = InnerFrame;
    });

    Library:AddToRegistry(Gradient, {
        Color = function()
            return ColorSequence.new({
                ColorSequenceKeypoint.new(0, Library:GetDarkerColor(Library.MainColor)),
                ColorSequenceKeypoint.new(1, Library.MainColor),
            });
        end
    });

    local WatermarkLabel = Library:CreateLabel({
        Position = UDim2.new(0, 5, 0, 0);
        Size = UDim2.new(1, -4, 1, 0);
        TextSize = 14;
        TextXAlignment = Enum.TextXAlignment.Left;
        ZIndex = 203;
        Parent = InnerFrame;
    });

    Library.Watermark = WatermarkOuter;
    Library.WatermarkText = WatermarkLabel;
    Library:MakeDraggable(Library.Watermark);



    local KeybindOuter = Library:Create('Frame', {
        AnchorPoint = Vector2.new(0, 0.5);
        BorderColor3 = Color3.new(0, 0, 0);
        Position = UDim2.new(0, 10, 0.5, 0);
        Size = UDim2.new(0, 210, 0, 20);
        Visible = false;
        ZIndex = 100;
        Parent = ScreenGui;
    });

    local KeybindInner = Library:Create('Frame', {
        BackgroundColor3 = Library.MainColor;
        BorderColor3 = Library.OutlineColor;
        BorderMode = Enum.BorderMode.Inset;
        Size = UDim2.new(1, 0, 1, 0);
        ZIndex = 101;
        Parent = KeybindOuter;
    });

    Library:AddToRegistry(KeybindInner, {
        BackgroundColor3 = 'MainColor';
        BorderColor3 = 'OutlineColor';
    }, true);

    local ColorFrame = Library:Create('Frame', {
        BackgroundColor3 = Library.AccentColor;
        BorderSizePixel = 0;
        Size = UDim2.new(1, 0, 0, 2);
        ZIndex = 102;
        Parent = KeybindInner;
    });

    Library:AddToRegistry(ColorFrame, {
        BackgroundColor3 = 'AccentColor';
    }, true);

    local KeybindLabel = Library:CreateLabel({
        Size = UDim2.new(1, 0, 0, 20);
        Position = UDim2.fromOffset(5, 2),
        TextXAlignment = Enum.TextXAlignment.Left,

        Text = 'Keybinds';
        ZIndex = 104;
        Parent = KeybindInner;
    });

    local KeybindContainer = Library:Create('Frame', {
        BackgroundTransparency = 1;
        Size = UDim2.new(1, 0, 1, -20);
        Position = UDim2.new(0, 0, 0, 20);
        ZIndex = 1;
        Parent = KeybindInner;
    });

    Library:Create('UIListLayout', {
        FillDirection = Enum.FillDirection.Vertical;
        SortOrder = Enum.SortOrder.LayoutOrder;
        Parent = KeybindContainer;
    });

    Library:Create('UIPadding', {
        PaddingLeft = UDim.new(0, 5),
        Parent = KeybindContainer,
    })

    Library.KeybindFrame = KeybindOuter;
    Library.KeybindContainer = KeybindContainer;
    Library:MakeDraggable(KeybindOuter);
end;

function Library:SetWatermarkVisibility(Bool)
    Library.Watermark.Visible = Bool;
end;

function Library:SetWatermark(Text)
    local X, Y = Library:GetTextBounds(Text, Library.Font, 14);
    Library.Watermark.Size = UDim2.new(0, X + 15, 0, (Y * 1.5) + 3);
    Library:SetWatermarkVisibility(true)

    Library.WatermarkText.Text = Text;
end;

function Library:Notify(Text, Time)
    local XSize, YSize = Library:GetTextBounds(Text, Library.Font, 14);

    YSize = YSize + 7

    local NotifyOuter = Library:Create('Frame', {
        BorderColor3 = Color3.new(0, 0, 0);
        Position = UDim2.new(0, 100, 0, 10);
        Size = UDim2.new(0, 0, 0, YSize);
        ClipsDescendants = true;
        ZIndex = 100;
        Parent = Library.NotificationArea;
    });

    local NotifyInner = Library:Create('Frame', {
        BackgroundColor3 = Library.MainColor;
        BorderColor3 = Library.OutlineColor;
        BorderMode = Enum.BorderMode.Inset;
        Size = UDim2.new(1, 0, 1, 0);
        ZIndex = 101;
        Parent = NotifyOuter;
    });

    Library:AddToRegistry(NotifyInner, {
        BackgroundColor3 = 'MainColor';
        BorderColor3 = 'OutlineColor';
    }, true);

    local InnerFrame = Library:Create('Frame', {
        BackgroundColor3 = Color3.new(1, 1, 1);
        BorderSizePixel = 0;
        Position = UDim2.new(0, 1, 0, 1);
        Size = UDim2.new(1, -2, 1, -2);
        ZIndex = 102;
        Parent = NotifyInner;
    });

    local Gradient = Library:Create('UIGradient', {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Library:GetDarkerColor(Library.MainColor)),
            ColorSequenceKeypoint.new(1, Library.MainColor),
        });
        Rotation = -90;
        Parent = InnerFrame;
    });

    Library:AddToRegistry(Gradient, {
        Color = function()
            return ColorSequence.new({
                ColorSequenceKeypoint.new(0, Library:GetDarkerColor(Library.MainColor)),
                ColorSequenceKeypoint.new(1, Library.MainColor),
            });
        end
    });

    local NotifyLabel = Library:CreateLabel({
        Position = UDim2.new(0, 4, 0, 0);
        Size = UDim2.new(1, -4, 1, 0);
        Text = Text;
        TextXAlignment = Enum.TextXAlignment.Left;
        TextSize = 14;
        ZIndex = 103;
        Parent = InnerFrame;
    });

    local LeftColor = Library:Create('Frame', {
        BackgroundColor3 = Library.AccentColor;
        BorderSizePixel = 0;
        Position = UDim2.new(0, -1, 0, -1);
        Size = UDim2.new(0, 3, 1, 2);
        ZIndex = 104;
        Parent = NotifyOuter;
    });

    Library:AddToRegistry(LeftColor, {
        BackgroundColor3 = 'AccentColor';
    }, true);

    pcall(NotifyOuter.TweenSize, NotifyOuter, UDim2.new(0, XSize + 8 + 4, 0, YSize), 'Out', 'Quad', 0.4, true);

    task.spawn(function()
        wait(Time or 5);

        pcall(NotifyOuter.TweenSize, NotifyOuter, UDim2.new(0, 0, 0, YSize), 'Out', 'Quad', 0.4, true);

        wait(0.4);

        NotifyOuter:Destroy();
    end);
end;

function Library:CreateWindow(...)
    local Arguments = { ... }
    local Config = { AnchorPoint = Vector2.zero }

    if type(...) == 'table' then
        Config = ...;
    else
        Config.Title = Arguments[1]
        Config.AutoShow = Arguments[2] or false;
    end

    if type(Config.Title) ~= 'string' then Config.Title = 'No title' end
    if type(Config.TabPadding) ~= 'number' then Config.TabPadding = 0 end
    if type(Config.MenuFadeTime) ~= 'number' then Config.MenuFadeTime = 0.2 end

    if typeof(Config.Position) ~= 'UDim2' then Config.Position = UDim2.fromOffset(175, 50) end
    if typeof(Config.Size) ~= 'UDim2' then Config.Size = UDim2.fromOffset(550, 600) end

    if Config.Center then
        Config.AnchorPoint = Vector2.new(0.5, 0.5)
        Config.Position = UDim2.fromScale(0.5, 0.5)
    end

    local Window = {
        Tabs = {};
    };

    local Outer = Library:Create('Frame', {
        AnchorPoint = Config.AnchorPoint,
        BackgroundColor3 = Color3.new(0, 0, 0);
        BorderSizePixel = 0;
        Position = Config.Position,
        Size = Config.Size,
        Visible = false;
        ZIndex = 1;
        Parent = ScreenGui;
    });

    Library:MakeDraggable(Outer, 25);

    local Inner = Library:Create('Frame', {
        BackgroundColor3 = Library.MainColor;
        BorderColor3 = Library.AccentColor;
        BorderMode = Enum.BorderMode.Inset;
        Position = UDim2.new(0, 1, 0, 1);
        Size = UDim2.new(1, -2, 1, -2);
        ZIndex = 1;
        Parent = Outer;
    });

    Library:AddToRegistry(Inner, {
        BackgroundColor3 = 'MainColor';
        BorderColor3 = 'AccentColor';
    });

    local WindowLabel = Library:CreateLabel({
        Position = UDim2.new(0, 7, 0, 0);
        Size = UDim2.new(0, 0, 0, 25);
        Text = Config.Title or '';
        TextXAlignment = Enum.TextXAlignment.Left;
        ZIndex = 1;
        Parent = Inner;
    });

    local MainSectionOuter = Library:Create('Frame', {
        BackgroundColor3 = Library.BackgroundColor;
        BorderColor3 = Library.OutlineColor;
        Position = UDim2.new(0, 8, 0, 25);
        Size = UDim2.new(1, -16, 1, -33);
        ZIndex = 1;
        Parent = Inner;
    });

    Library:AddToRegistry(MainSectionOuter, {
        BackgroundColor3 = 'BackgroundColor';
        BorderColor3 = 'OutlineColor';
    });

    local MainSectionInner = Library:Create('Frame', {
        BackgroundColor3 = Library.BackgroundColor;
        BorderColor3 = Color3.new(0, 0, 0);
        BorderMode = Enum.BorderMode.Inset;
        Position = UDim2.new(0, 0, 0, 0);
        Size = UDim2.new(1, 0, 1, 0);
        ZIndex = 1;
        Parent = MainSectionOuter;
    });

    Library:AddToRegistry(MainSectionInner, {
        BackgroundColor3 = 'BackgroundColor';
    });

    local TabArea = Library:Create('Frame', {
        BackgroundTransparency = 1;
        Position = UDim2.new(0, 8, 0, 8);
        Size = UDim2.new(1, -16, 0, 21);
        ZIndex = 1;
        Parent = MainSectionInner;
    });

    local TabListLayout = Library:Create('UIListLayout', {
        Padding = UDim.new(0, Config.TabPadding);
        FillDirection = Enum.FillDirection.Horizontal;
        SortOrder = Enum.SortOrder.LayoutOrder;
        Parent = TabArea;
    });

    local TabContainer = Library:Create('Frame', {
        BackgroundColor3 = Library.MainColor;
        BorderColor3 = Library.OutlineColor;
        Position = UDim2.new(0, 8, 0, 30);
        Size = UDim2.new(1, -16, 1, -38);
        ZIndex = 2;
        Parent = MainSectionInner;
    });
    

    Library:AddToRegistry(TabContainer, {
        BackgroundColor3 = 'MainColor';
        BorderColor3 = 'OutlineColor';
    });

    function Window:SetWindowTitle(Title)
        WindowLabel.Text = Title;
    end;

    function Window:AddTab(Name)
        local Tab = {
            Groupboxes = {};
            Tabboxes = {};
        };

        local TabButtonWidth = Library:GetTextBounds(Name, Library.Font, 16);

        local TabButton = Library:Create('Frame', {
            BackgroundColor3 = Library.BackgroundColor;
            BorderColor3 = Library.OutlineColor;
            Size = UDim2.new(0, TabButtonWidth + 8 + 4, 1, 0);
            ZIndex = 1;
            Parent = TabArea;
        });

        Library:AddToRegistry(TabButton, {
            BackgroundColor3 = 'BackgroundColor';
            BorderColor3 = 'OutlineColor';
        });

        local TabButtonLabel = Library:CreateLabel({
            Position = UDim2.new(0, 0, 0, 0);
            Size = UDim2.new(1, 0, 1, -1);
            Text = Name;
            ZIndex = 1;
            Parent = TabButton;
        });

        local Blocker = Library:Create('Frame', {
            BackgroundColor3 = Library.MainColor;
            BorderSizePixel = 0;
            Position = UDim2.new(0, 0, 1, 0);
            Size = UDim2.new(1, 0, 0, 1);
            BackgroundTransparency = 1;
            ZIndex = 3;
            Parent = TabButton;
        });

        Library:AddToRegistry(Blocker, {
            BackgroundColor3 = 'MainColor';
        });

        local TabFrame = Library:Create('Frame', {
            Name = 'TabFrame',
            BackgroundTransparency = 1;
            Position = UDim2.new(0, 0, 0, 0);
            Size = UDim2.new(1, 0, 1, 0);
            Visible = false;
            ZIndex = 2;
            Parent = TabContainer;
        });

        local LeftSide = Library:Create('ScrollingFrame', {
            BackgroundTransparency = 1;
            BorderSizePixel = 0;
            Position = UDim2.new(0, 8 - 1, 0, 8 - 1);
            Size = UDim2.new(0.5, -12 + 2, 0, 507 + 2);
            CanvasSize = UDim2.new(0, 0, 0, 0);
            BottomImage = '';
            TopImage = '';
            ScrollBarThickness = 0;
            ZIndex = 2;
            Parent = TabFrame;
        });

        local RightSide = Library:Create('ScrollingFrame', {
            BackgroundTransparency = 1;
            BorderSizePixel = 0;
            Position = UDim2.new(0.5, 4 + 1, 0, 8 - 1);
            Size = UDim2.new(0.5, -12 + 2, 0, 507 + 2);
            CanvasSize = UDim2.new(0, 0, 0, 0);
            BottomImage = '';
            TopImage = '';
            ScrollBarThickness = 0;
            ZIndex = 2;
            Parent = TabFrame;
        });

        Library:Create('UIListLayout', {
            Padding = UDim.new(0, 8);
            FillDirection = Enum.FillDirection.Vertical;
            SortOrder = Enum.SortOrder.LayoutOrder;
            HorizontalAlignment = Enum.HorizontalAlignment.Center;
            Parent = LeftSide;
        });

        Library:Create('UIListLayout', {
            Padding = UDim.new(0, 8);
            FillDirection = Enum.FillDirection.Vertical;
            SortOrder = Enum.SortOrder.LayoutOrder;
            HorizontalAlignment = Enum.HorizontalAlignment.Center;
            Parent = RightSide;
        });

        for _, Side in next, { LeftSide, RightSide } do
            Side:WaitForChild('UIListLayout'):GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
                Side.CanvasSize = UDim2.fromOffset(0, Side.UIListLayout.AbsoluteContentSize.Y);
            end);
        end;

        function Tab:ShowTab()
            for _, Tab in next, Window.Tabs do
                Tab:HideTab();
            end;

            Blocker.BackgroundTransparency = 0;
            TabButton.BackgroundColor3 = Library.MainColor;
            Library.RegistryMap[TabButton].Properties.BackgroundColor3 = 'MainColor';
            TabFrame.Visible = true;
        end;

        function Tab:HideTab()
            Blocker.BackgroundTransparency = 1;
            TabButton.BackgroundColor3 = Library.BackgroundColor;
            Library.RegistryMap[TabButton].Properties.BackgroundColor3 = 'BackgroundColor';
            TabFrame.Visible = false;
        end;

        function Tab:SetLayoutOrder(Position)
            TabButton.LayoutOrder = Position;
            TabListLayout:ApplyLayout();
        end;

        function Tab:AddGroupbox(Info)
            local Groupbox = {};

            local BoxOuter = Library:Create('Frame', {
                BackgroundColor3 = Library.BackgroundColor;
                BorderColor3 = Library.OutlineColor;
                BorderMode = Enum.BorderMode.Inset;
                Size = UDim2.new(1, 0, 0, 507 + 2);
                ZIndex = 2;
                Parent = Info.Side == 1 and LeftSide or RightSide;
            });

            Library:AddToRegistry(BoxOuter, {
                BackgroundColor3 = 'BackgroundColor';
                BorderColor3 = 'OutlineColor';
            });

            local BoxInner = Library:Create('Frame', {
                BackgroundColor3 = Library.BackgroundColor;
                BorderColor3 = Color3.new(0, 0, 0);
                -- BorderMode = Enum.BorderMode.Inset;
                Size = UDim2.new(1, -2, 1, -2);
                Position = UDim2.new(0, 1, 0, 1);
                ZIndex = 4;
                Parent = BoxOuter;
            });

            Library:AddToRegistry(BoxInner, {
                BackgroundColor3 = 'BackgroundColor';
            });

            local Highlight = Library:Create('Frame', {
                BackgroundColor3 = Library.AccentColor;
                BorderSizePixel = 0;
                Size = UDim2.new(1, 0, 0, 2);
                ZIndex = 5;
                Parent = BoxInner;
            });

            Library:AddToRegistry(Highlight, {
                BackgroundColor3 = 'AccentColor';
            });

            local GroupboxLabel = Library:CreateLabel({
                Size = UDim2.new(1, 0, 0, 18);
                Position = UDim2.new(0, 4, 0, 2);
                TextSize = 14;
                Text = Info.Name;
                TextXAlignment = Enum.TextXAlignment.Left;
                ZIndex = 5;
                Parent = BoxInner;
            });

            local Container = Library:Create('Frame', {
                BackgroundTransparency = 1;
                Position = UDim2.new(0, 4, 0, 20);
                Size = UDim2.new(1, -4, 1, -20);
                ZIndex = 1;
                Parent = BoxInner;
            });

            Library:Create('UIListLayout', {
                FillDirection = Enum.FillDirection.Vertical;
                SortOrder = Enum.SortOrder.LayoutOrder;
                Parent = Container;
            });

            function Groupbox:Resize()
                local Size = 0;

                for _, Element in next, Groupbox.Container:GetChildren() do
                    if (not Element:IsA('UIListLayout')) and Element.Visible then
                        Size = Size + Element.Size.Y.Offset;
                    end;
                end;

                BoxOuter.Size = UDim2.new(1, 0, 0, 20 + Size + 2 + 2);
            end;

            Groupbox.Container = Container;
            setmetatable(Groupbox, BaseGroupbox);

            Groupbox:AddBlank(3);
            Groupbox:Resize();

            Tab.Groupboxes[Info.Name] = Groupbox;

            return Groupbox;
        end;

        function Tab:AddLeftGroupbox(Name)
            return Tab:AddGroupbox({ Side = 1; Name = Name; });
        end;

        function Tab:AddRightGroupbox(Name)
            return Tab:AddGroupbox({ Side = 2; Name = Name; });
        end;

        function Tab:AddTabbox(Info)
            local Tabbox = {
                Tabs = {};
            };

            local BoxOuter = Library:Create('Frame', {
                BackgroundColor3 = Library.BackgroundColor;
                BorderColor3 = Library.OutlineColor;
                BorderMode = Enum.BorderMode.Inset;
                Size = UDim2.new(1, 0, 0, 0);
                ZIndex = 2;
                Parent = Info.Side == 1 and LeftSide or RightSide;
            });

            Library:AddToRegistry(BoxOuter, {
                BackgroundColor3 = 'BackgroundColor';
                BorderColor3 = 'OutlineColor';
            });

            local BoxInner = Library:Create('Frame', {
                BackgroundColor3 = Library.BackgroundColor;
                BorderColor3 = Color3.new(0, 0, 0);
                -- BorderMode = Enum.BorderMode.Inset;
                Size = UDim2.new(1, -2, 1, -2);
                Position = UDim2.new(0, 1, 0, 1);
                ZIndex = 4;
                Parent = BoxOuter;
            });

            Library:AddToRegistry(BoxInner, {
                BackgroundColor3 = 'BackgroundColor';
            });

            local Highlight = Library:Create('Frame', {
                BackgroundColor3 = Library.AccentColor;
                BorderSizePixel = 0;
                Size = UDim2.new(1, 0, 0, 2);
                ZIndex = 10;
                Parent = BoxInner;
            });

            Library:AddToRegistry(Highlight, {
                BackgroundColor3 = 'AccentColor';
            });

            local TabboxButtons = Library:Create('Frame', {
                BackgroundTransparency = 1;
                Position = UDim2.new(0, 0, 0, 1);
                Size = UDim2.new(1, 0, 0, 18);
                ZIndex = 5;
                Parent = BoxInner;
            });

            Library:Create('UIListLayout', {
                FillDirection = Enum.FillDirection.Horizontal;
                HorizontalAlignment = Enum.HorizontalAlignment.Left;
                SortOrder = Enum.SortOrder.LayoutOrder;
                Parent = TabboxButtons;
            });

            function Tabbox:AddTab(Name)
                local Tab = {};

                local Button = Library:Create('Frame', {
                    BackgroundColor3 = Library.MainColor;
                    BorderColor3 = Color3.new(0, 0, 0);
                    Size = UDim2.new(0.5, 0, 1, 0);
                    ZIndex = 6;
                    Parent = TabboxButtons;
                });

                Library:AddToRegistry(Button, {
                    BackgroundColor3 = 'MainColor';
                });

                local ButtonLabel = Library:CreateLabel({
                    Size = UDim2.new(1, 0, 1, 0);
                    TextSize = 14;
                    Text = Name;
                    TextXAlignment = Enum.TextXAlignment.Center;
                    ZIndex = 7;
                    Parent = Button;
                });

                local Block = Library:Create('Frame', {
                    BackgroundColor3 = Library.BackgroundColor;
                    BorderSizePixel = 0;
                    Position = UDim2.new(0, 0, 1, 0);
                    Size = UDim2.new(1, 0, 0, 1);
                    Visible = false;
                    ZIndex = 9;
                    Parent = Button;
                });

                Library:AddToRegistry(Block, {
                    BackgroundColor3 = 'BackgroundColor';
                });

                local Container = Library:Create('Frame', {
                    BackgroundTransparency = 1;
                    Position = UDim2.new(0, 4, 0, 20);
                    Size = UDim2.new(1, -4, 1, -20);
                    ZIndex = 1;
                    Visible = false;
                    Parent = BoxInner;
                });

                Library:Create('UIListLayout', {
                    FillDirection = Enum.FillDirection.Vertical;
                    SortOrder = Enum.SortOrder.LayoutOrder;
                    Parent = Container;
                });

                function Tab:Show()
                    for _, Tab in next, Tabbox.Tabs do
                        Tab:Hide();
                    end;

                    Container.Visible = true;
                    Block.Visible = true;

                    Button.BackgroundColor3 = Library.BackgroundColor;
                    Library.RegistryMap[Button].Properties.BackgroundColor3 = 'BackgroundColor';

                    Tab:Resize();
                end;

                function Tab:Hide()
                    Container.Visible = false;
                    Block.Visible = false;

                    Button.BackgroundColor3 = Library.MainColor;
                    Library.RegistryMap[Button].Properties.BackgroundColor3 = 'MainColor';
                end;

                function Tab:Resize()
                    local TabCount = 0;

                    for _, Tab in next, Tabbox.Tabs do
                        TabCount = TabCount + 1;
                    end;

                    for _, Button in next, TabboxButtons:GetChildren() do
                        if not Button:IsA('UIListLayout') then
                            Button.Size = UDim2.new(1 / TabCount, 0, 1, 0);
                        end;
                    end;

                    if (not Container.Visible) then
                        return;
                    end;

                    local Size = 0;

                    for _, Element in next, Tab.Container:GetChildren() do
                        if (not Element:IsA('UIListLayout')) and Element.Visible then
                            Size = Size + Element.Size.Y.Offset;
                        end;
                    end;

                    BoxOuter.Size = UDim2.new(1, 0, 0, 20 + Size + 2 + 2);
                end;

                Button.InputBegan:Connect(function(Input)
                    if Input.UserInputType == Enum.UserInputType.MouseButton1 and not Library:MouseIsOverOpenedFrame() then
                        Tab:Show();
                        Tab:Resize();
                    end;
                end);

                Tab.Container = Container;
                Tabbox.Tabs[Name] = Tab;

                setmetatable(Tab, BaseGroupbox);

                Tab:AddBlank(3);
                Tab:Resize();

                -- Show first tab (number is 2 cus of the UIListLayout that also sits in that instance)
                if #TabboxButtons:GetChildren() == 2 then
                    Tab:Show();
                end;

                return Tab;
            end;

            Tab.Tabboxes[Info.Name or ''] = Tabbox;

            return Tabbox;
        end;

        function Tab:AddLeftTabbox(Name)
            return Tab:AddTabbox({ Name = Name, Side = 1; });
        end;

        function Tab:AddRightTabbox(Name)
            return Tab:AddTabbox({ Name = Name, Side = 2; });
        end;

        TabButton.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                Tab:ShowTab();
            end;
        end);

        -- This was the first tab added, so we show it by default.
        if #TabContainer:GetChildren() == 1 then
            Tab:ShowTab();
        end;

        Window.Tabs[Name] = Tab;
        return Tab;
    end;

    local ModalElement = Library:Create('TextButton', {
        BackgroundTransparency = 1;
        Size = UDim2.new(0, 0, 0, 0);
        Visible = true;
        Text = '';
        Modal = false;
        Parent = ScreenGui;
    });

    local TransparencyCache = {};
    local Toggled = false;
    local Fading = false;

    function Library:Toggle()
        if Fading then
            return;
        end;

        local FadeTime = Config.MenuFadeTime;
        Fading = true;
        Toggled = (not Toggled);
        ModalElement.Modal = Toggled;

        if Toggled then
            -- A bit scuffed, but if we're going from not toggled -> toggled we want to show the frame immediately so that the fade is visible.
            Outer.Visible = true;

            task.spawn(function()
                -- TODO: add cursor fade?
                local State = InputService.MouseIconEnabled;

                local Cursor = Drawing.new('Triangle');
                Cursor.Thickness = 1;
                Cursor.Filled = true;
                Cursor.Visible = true;

                local CursorOutline = Drawing.new('Triangle');
                CursorOutline.Thickness = 1;
                CursorOutline.Filled = false;
                CursorOutline.Color = Color3.new(0, 0, 0);
                CursorOutline.Visible = true;

                while Toggled and ScreenGui.Parent do
                    InputService.MouseIconEnabled = false;

                    local mPos = InputService:GetMouseLocation();

                    Cursor.Color = Library.AccentColor;

                    Cursor.PointA = Vector2.new(mPos.X, mPos.Y);
                    Cursor.PointB = Vector2.new(mPos.X + 16, mPos.Y + 6);
                    Cursor.PointC = Vector2.new(mPos.X + 6, mPos.Y + 16);

                    CursorOutline.PointA = Cursor.PointA;
                    CursorOutline.PointB = Cursor.PointB;
                    CursorOutline.PointC = Cursor.PointC;

                    RenderStepped:Wait();
                end;

                InputService.MouseIconEnabled = State;

                Cursor:Remove();
                CursorOutline:Remove();
            end);
        end;

        for _, Desc in next, Outer:GetDescendants() do
            local Properties = {};

            if Desc:IsA('ImageLabel') then
                table.insert(Properties, 'ImageTransparency');
                table.insert(Properties, 'BackgroundTransparency');
            elseif Desc:IsA('TextLabel') or Desc:IsA('TextBox') then
                table.insert(Properties, 'TextTransparency');
            elseif Desc:IsA('Frame') or Desc:IsA('ScrollingFrame') then
                table.insert(Properties, 'BackgroundTransparency');
            elseif Desc:IsA('UIStroke') then
                table.insert(Properties, 'Transparency');
            end;

            local Cache = TransparencyCache[Desc];

            if (not Cache) then
                Cache = {};
                TransparencyCache[Desc] = Cache;
            end;

            for _, Prop in next, Properties do
                if not Cache[Prop] then
                    Cache[Prop] = Desc[Prop];
                end;

                if Cache[Prop] == 1 then
                    continue;
                end;

                TweenService:Create(Desc, TweenInfo.new(FadeTime, Enum.EasingStyle.Linear), { [Prop] = Toggled and Cache[Prop] or 1 }):Play();
            end;
        end;

        task.wait(FadeTime);

        Outer.Visible = Toggled;

        Fading = false;
    end

    Library:GiveSignal(InputService.InputBegan:Connect(function(Input, Processed)
        if type(Library.ToggleKeybind) == 'table' and Library.ToggleKeybind.Type == 'KeyPicker' then
            if Input.UserInputType == Enum.UserInputType.Keyboard and Input.KeyCode.Name == Library.ToggleKeybind.Value then
                task.spawn(Library.Toggle)
            end
        elseif Input.KeyCode == Enum.KeyCode.RightControl or (Input.KeyCode == Enum.KeyCode.RightShift and (not Processed)) then
            task.spawn(Library.Toggle)
        end
    end))

    if Config.AutoShow then task.spawn(Library.Toggle) end

    Window.Holder = Outer;

    return Window;
end;

local function OnPlayerChange()
    local PlayerList = GetPlayersString();

    for _, Value in next, Options do
        if Value.Type == 'Dropdown' and Value.SpecialType == 'Player' then
            Value:SetValues(PlayerList);
        end;
    end;
end;

Players.PlayerAdded:Connect(OnPlayerChange);
Players.PlayerRemoving:Connect(OnPlayerChange);

getgenv().Library = Library
return Library
}
local ThemeManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/refs/heads/main/addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/refs/heads/main/addons/SaveManager.lua"))()

local Window = Library:CreateWindow({
  Title = "🌚ASTRO.CC🌚",
  Center = true,
  AutoShow = true,
  TabPadding = 8,
  MenuFadeTime = 0.2
})

local Tabs = {
    ['Combat'] = Window:AddTab('Combat'),
    ['Visuals'] = Window:AddTab('Visuals'),
    ['Misc'] = Window:AddTab('Misc'),
    ['Credits'] = Window:AddTab('Credits'),
    ['UI Settings'] = Window:AddTab('Configs'),
}





--// COMBAT \\--
local TabBox = Tabs.Combat:AddLeftTabbox()
local ExploitsTab = TabBox:AddTab('EXPLOITS')


local longneck = {
    LongNeckEnabled = false,
    UpperLimitDefault = 3,
    LowerLimitDefault = 1.75,
    CurrentSliderValue = 1.75,
    }
    
    ExploitsTab:AddToggle('LongNeck', {Text = 'long neck', Default = false, Tooltip}):AddKeyPicker('LongNeckKey', {Default = 'Non', SyncToggleState = true, Mode = 'Toggle', Text = 'Long Neck', NoUI = false}):OnChanged(function(value)
    longneck.LongNeckEnabled = value
    if not longneck.LongNeckEnabled then
    game:GetService("Workspace").Ignore.LocalCharacter.Bottom.PrismaticConstraint.UpperLimit = longneck.UpperLimitDefault
    game:GetService("Workspace").Ignore.LocalCharacter.Bottom.PrismaticConstraint.LowerLimit = longneck.LowerLimitDefault
    else
    game:GetService("Workspace").Ignore.LocalCharacter.Bottom.PrismaticConstraint.UpperLimit = longneck.CurrentSliderValue
    game:GetService("Workspace").Ignore.LocalCharacter.Bottom.PrismaticConstraint.LowerLimit = longneck.CurrentSliderValue
    end
    end)
    
    ExploitsTab:AddSlider('HeightChangerSlider', {Text = 'height:', Suffix = "m", Default = 4, Min = 0, Max = 8; Rounding = 1, Compact = false}):OnChanged(function(Value)
    longneck.CurrentSliderValue = Value
    if longneck.LongNeckEnabled then
    game:GetService("Workspace").Ignore.LocalCharacter.Bottom.PrismaticConstraint.LowerLimit = Value
    game:GetService("Workspace").Ignore.LocalCharacter.Bottom.PrismaticConstraint.UpperLimit = Value
    end
    end)

    local HeadHitboxTabBox = Tabs.Combat:AddLeftTabbox('head hitbox')
    local HeadHitboxTab = HeadHitboxTabBox:AddTab('head hitbox')
    
    local antihitbox
    antihitbox = hookmetamethod(game, "__index", newcclosure(function(...)
    local self, k = ...
    if not checkcaller() and k == "Size" and self.Name == "Head" then
      return Vector3.new(1.672248125076294, 0.835624098777771, 0.835624098777771)
    end
    return antihitbox(...)
    end))
    
    --* Head Hitbox Expander *--
    
    local HedsOn = Instance.new("Part")
    HedsOn.Name = "HedsOn"
    HedsOn.Anchored = false
    HedsOn.CanCollide = false
    HedsOn.Transparency = 0
    HedsOn.Size = Vector3.new(10, 10, 10)
    HedsOn.Parent = game.ReplicatedStorage
    
    local HeadExtends = false
    local XSize = 10
    local YSize = 10
    local ZSize = 10
    local HitboxTransparency = 10
    
    HeadHitboxTab:AddToggle('HBO',{Text='enabled',Default=false}):OnChanged(function(Value)
    HeadExtends = Value
    end)
    
    HeadHitboxTab:AddSlider('HitboxXSize_Slider', {Text = 'hitbox width:', Default = 5, Min = 0, Max = 10, Rounding = 2, Suffix = "%", Compact = false}):OnChanged(function(HitboxXSize)
    XSize = HitboxXSize
    end)
    
    HeadHitboxTab:AddSlider('HitboxYSize_Slider', {Text = 'hitbox height:', Default = 5, Min = 0, Max = 10, Rounding = 2, Suffix = "%", Compact = false}):OnChanged(function(HitboxYSize)
    YSize = HitboxYSize
    end)
    
    HeadHitboxTab:AddSlider('HitboxXSize_Slider', {Text = 'transparency:', Default = 10, Min = 0, Max = 60, Rounding = 0, Suffix = "%", Compact = false}):OnChanged(function(TransparencyValue)
    HitboxTransparency = TransparencyValue / 100
    end)
    
    task.spawn(function()
    while task.wait() do
      if HeadExtends then
        for _, i in ipairs(game:GetService("Workspace"):GetChildren()) do
          if i:FindFirstChild("HumanoidRootPart") and not i:FindFirstChild("HedsOn") then
            local BigHeadsPart = Instance.new("Part")
            BigHeadsPart.Name = "Head"
            BigHeadsPart.Anchored = false
            BigHeadsPart.CanCollide = false
            BigHeadsPart.Transparency = HitboxTransparency
            BigHeadsPart.Size = Vector3.new(XSize, YSize, ZSize)
            local DeletePart = Instance.new("Weld")
            DeletePart.Parent = BigHeadsPart
            DeletePart.Name = "FAKEHEAD"
            local HeadsParts = BigHeadsPart:Clone()
            HeadsParts.Parent = i
            HeadsParts.Orientation = i.HumanoidRootPart.Orientation
            local clonedHedsOn = HedsOn:Clone()
            clonedHedsOn.Parent = i
            local Headswelding = Instance.new("Weld")
            Headswelding.Parent = HeadsParts
            Headswelding.Part0 = i.HumanoidRootPart
            Headswelding.Part1 = HeadsParts
            HeadsParts.Position = Vector3.new(i.HumanoidRootPart.Position.X, i.HumanoidRootPart.Position.Y - 0.6, i.HumanoidRootPart.Position.Z)
          end
        end
      else
        for _, i in ipairs(game:GetService("Workspace"):GetChildren()) do
          if i:FindFirstChild("HumanoidRootPart") and i:FindFirstChild("HedsOn") then
            i.HedsOn:Remove()
            for _, a in ipairs(i:GetChildren()) do
              if a.Name == "Head" and a:FindFirstChild("FAKEHEAD") and (not a:FindFirstChild("Nametag") or not a:FindFirstChild("Face")) then
                a:Remove()
              end
            end
          end
        end
      end
    end
    end)
    












local CustomHitsoundsTabBox = Tabs.Misc:AddLeftTabbox('Custom Hitsounds')
local PlayerHitsoundsTab = CustomHitsoundsTabBox:AddTab('Player Hitsounds')
local NatureHitsoundsTab = CustomHitsoundsTabBox:AddTab('Nature Hitsounds')

local sounds = {
  ["Defualt Headshot Hit"] = "rbxassetid://9119561046",
  ["Defualt Body Hit"] = "rbxassetid://9114487369",
  ["Defualt Wood Hit"] = "rbxassetid://9125573608",
  ["Defualt Rock Hit"] = "rbxassetid://9118630389",
  Neverlose = "rbxassetid://8726881116",
  Gamesense = "rbxassetid://4817809188",
  One = "rbxassetid://7380502345",
  Bell = "rbxassetid://6534947240",
  Rust = "rbxassetid://1255040462",
  TF2 = "rbxassetid://2868331684",
  Slime = "rbxassetid://6916371803",
  ["Among Us"] = "rbxassetid://5700183626",
  Minecraft = "rbxassetid://4018616850",
  ["CS:GO"] = "rbxassetid://6937353691",
  Saber = "rbxassetid://8415678813",
  Baimware = "rbxassetid://3124331820",
  Osu = "rbxassetid://7149255551",
  ["TF2 Critical"] = "rbxassetid://296102734",
  Bat = "rbxassetid://3333907347",
  ["Call of Duty"] = "rbxassetid://5952120301",
  Bubble = "rbxassetid://6534947588",
  Pick = "rbxassetid://1347140027",
  Pop = "rbxassetid://198598793",
  Bruh = "rbxassetid://4275842574",
  Bamboo = "rbxassetid://3769434519",
  Crowbar = "rbxassetid://546410481",
  Weeb = "rbxassetid://6442965016",
  Beep = "rbxassetid://8177256015",
  Bambi = "rbxassetid://8437203821",
  Stone = "rbxassetid://3581383408",
  ["Old Fatality"] = "rbxassetid://6607142036",
  Click = "rbxassetid://8053704437",
  Ding = "rbxassetid://7149516994",
  Snow = "rbxassetid://6455527632",
  Laser = "rbxassetid://7837461331",
  Mario = "rbxassetid://2815207981",
  Steve = "rbxassetid://4965083997",
  Snowdrake = "rbxassetid://7834724809"
  }

local SoundService = game:GetService("SoundService")

SoundService.PlayerHitHeadshot.Volume = 5
SoundService.PlayerHitHeadshot.Pitch = 1
SoundService.PlayerHitHeadshot.EqualizerSoundEffect.HighGain = -2

-- GAME 
PlayerHitsoundsTab:AddToggle('Enabled_Toggle1', {Text = 'Enabled', Default = false})

PlayerHitsoundsTab:AddDropdown('HeadshotHit', {Values = { 'Defualt Headshot Hit','Neverlose','Gamesense','One','Bell','Rust','TF2','Slime','Among Us','Minecraft','CS:GO','Saber','Baimware','Osu','TF2 Critical','Bat','Call of Duty','Bubble','Pick','Pop','Bruh','Bamboo','Crowbar','Weeb','Beep','Bambi','Stone','Old Fatality','Click','Ding','Snow','Laser','Mario','Steve','Snowdrake' },Default = 1, Multi = false, Text = 'Head Hitsound:'})
Options.HeadshotHit:OnChanged(function()
local soundId = sounds[Options.HeadshotHit.Value]
game:GetService("SoundService").PlayerHitHeadshot.SoundId = soundId
end)

PlayerHitsoundsTab:AddSlider('Volume_Slider', {Text = 'Volume', Default = 5, Min = 0, Max = 10, Rounding = 0, Compact = true,}):OnChanged(function(vol)
SoundService.PlayerHitHeadshot.Volume = vol
end)

PlayerHitsoundsTab:AddSlider('Pitch_Slider', {Text = 'Pitch', Default = 1, Min = 0, Max = 2, Rounding = 1, Compact = true,}):OnChanged(function(pich)
SoundService.PlayerHitHeadshot.Pitch = pich
end)
--
PlayerHitsoundsTab:AddToggle('Enabled_Toggle2', {Text = 'Enabled', Default = false})

PlayerHitsoundsTab:AddDropdown('Hit', {Values = { 'Defualt Body Hit','Neverlose','Gamesense','One','Bell','Rust','TF2','Slime','Among Us','Minecraft','CS:GO','Saber','Baimware','Osu','TF2 Critical','Bat','Call of Duty','Bubble','Pick','Pop','Bruh','Bamboo','Crowbar','Weeb','Beep','Bambi','Stone','Old Fatality','Click','Ding','Snow','Laser','Mario','Steve','Snowdrake' },Default = 1, Multi = false, Text = 'Body Hitsound:'})
Options.Hit:OnChanged(function()
local soundId = sounds[Options.Hit.Value]
game:GetService("SoundService").PlayerHit2.SoundId = soundId
end)

PlayerHitsoundsTab:AddSlider('Volume_Slider', {Text = 'Volume', Default = 5, Min = 0, Max = 10, Rounding = 0, Compact = true,}):OnChanged(function(vole)
SoundService.PlayerHit2.Volume = vole
end)

PlayerHitsoundsTab:AddSlider('Pitch_Slider', {Text = 'Pitch', Default = 1, Min = 0, Max = 2, Rounding = 1, Compact = true,}):OnChanged(function(piche)
SoundService.PlayerHit2.Pitch = piche
end)

--* Nature Hitsounds *--

NatureHitsoundsTab:AddToggle('Enabled_Toggle2', {Text = 'Enabled', Default = false})

NatureHitsoundsTab:AddDropdown('WoodHit', {Values = { 'Defualt Wood Hit','Neverlose','Gamesense','One','Bell','Rust','TF2','Slime','Among Us','Minecraft','CS:GO','Saber','Baimware','Osu','TF2 Critical','Bat','Call of Duty','Bubble','Pick','Pop','Bruh','Bamboo','Crowbar','Weeb','Beep','Bambi','Stone','Old Fatality','Click','Ding','Snow','Laser','Mario','Steve','Snowdrake' },Default = 1, Multi = false, Text = 'Wood Hitsound:'})
Options.WoodHit:OnChanged(function()
local soundId = sounds[Options.WoodHit.Value]
game:GetService("SoundService").WoodHit.SoundId = soundId
end)

NatureHitsoundsTab:AddSlider('Volume_Slider', {Text = 'Volume', Default = 5, Min = 0, Max = 10, Rounding = 0, Compact = true,}):OnChanged(function(vole)
SoundService.WoodHit.Volume = vole
end)

NatureHitsoundsTab:AddSlider('Pitch_Slider', {Text = 'Pitch', Default = 1, Min = 0, Max = 2, Rounding = 1, Compact = true,}):OnChanged(function(piche)
SoundService.WoodHit.Pitch = piche
end)
--
NatureHitsoundsTab:AddToggle('Enabled_Toggle1', {Text = 'Enabled', Default = false})

NatureHitsoundsTab:AddDropdown('RockHit', {Values = { 'Defualt Rock Hit','Neverlose','Gamesense','One','Bell','Rust','TF2','Slime','Among Us','Minecraft','CS:GO','Saber','Baimware','Osu','TF2 Critical','Bat','Call of Duty','Bubble','Pick','Pop','Bruh','Bamboo','Crowbar','Weeb','Beep','Bambi','Stone','Old Fatality','Click','Ding','Snow','Laser','Mario','Steve','Snowdrake' },Default = 1, Multi = false, Text = 'Rock Hitsound:'})
Options.RockHit:OnChanged(function()
local soundId = sounds[Options.RockHit.Value]
game:GetService("SoundService").RockHit.SoundId = soundId
end)

NatureHitsoundsTab:AddSlider('Volume_Slider', {Text = 'Volume', Default = 5, Min = 0, Max = 10, Rounding = 0, Compact = true,}):OnChanged(function(vol)
SoundService.RockHit.Volume = vol
end)

NatureHitsoundsTab:AddSlider('Pitch_Slider', {Text = 'Pitch', Default = 1, Min = 0, Max = 2, Rounding = 1, Compact = true,}):OnChanged(function(pich)
SoundService.RockHit.Pitch = pich
end)







local WeaponModsTabBox = Tabs.Combat:AddRightTabbox('weapon modifications')
local WeaponModsTab = WeaponModsTabBox:AddTab('weapon modifications')

--* Weapon Modifications *--
local gunMods = {
  norecoilTog = false,
  noSpreadTog = false,
  firerateMultiTog = false,
  firerateMulti = 1,
  noReloadanimTog = false,
}

local GunModsEnabled = false
WeaponModsTab:AddToggle('FireTypeEnabled', {Text = 'enabled', Default = false}):OnChanged(function(EnabledFireType)
GunModsEnabled = EnabledFireType
end)

WeaponModsTab:AddToggle('Firerate',{Text='firerate',Default=false}):OnChanged(function(Value)
gunMods.firerateMultiTog = Value
end)

WeaponModsTab:AddSlider('firerateMultiS', {Text='multi:',Default=0.5,Min=0.1,Max=1,Rounding=2,Compact=false}):OnChanged(function(Value)
gunMods.firerateMulti = Value
end)
local oldAttackCooldown;oldAttackCooldown = hookfunction(getupvalues(getrenv()._G.modules.FPS.ToolControllers.RangedWeapon.PlayerFire)[1],function(...)
local arg = {...}
if GunModsEnabled and gunMods.firerateMultiTog == true then
  arg[2]['AttackCooldown'] = gunMods.firerateMulti
  return oldAttackCooldown(unpack(arg))
end
return oldAttackCooldown(...)
end)

local ItemConfigs = game.ReplicatedStorage.ItemConfigs
local weapons = {PipePistol = require(ItemConfigs.PipePistol),Blunderbuss = require(ItemConfigs.Blunderbuss),Crossbow = require(ItemConfigs.Crossbow),Bow = require(ItemConfigs.Bow),USP9 = require(ItemConfigs.USP9),LeverActionRifle = require(ItemConfigs.LeverActionRifle),GaussRifle = require(ItemConfigs.GaussRifle)}
local FireActions = {Semi = "semi",Auto = "auto"}
WeaponModsTab:AddDropdown('FireTypeDropdown', {Values = {"Semi", "Auto"},Default = 1,Multi = false,Text = 'fire type:'}):OnChanged(function(Value)
if GunModsEnabled then
  local fireAction = FireActions[Value]
  for _, weapon in pairs(weapons) do
    weapon.FireAction = fireAction
  end
end
end)



local Recoil_Value = 2
WeaponModsTab:AddSlider('RecoilStrength', {Text = 'recoil:', Default = Recoil_Value, Min = 1, Max = 100, Suffix = "%", Rounding = 0, Compact = false}):OnChanged(function(Value)
Recoil_Value = Value / 50
end)


local NoRecoil; NoRecoil = hookfunction(getrenv()._G.modules.Camera.Recoil, function(...)
    args = {...}
    if GunModsEnabled then
    args[1]["cameraY"] = Recoil_Value / 50;args[1]["cameraX"] = Recoil_Value / 50
    return NoRecoil(unpack(args))
    end
    end)












--// VISUALS \\--


local ArmVisTabBox = Tabs.Visuals:AddRightTabbox('arm visuals')
local ArmVisTab = ArmVisTabBox:AddTab('local chams')



local function setArmProperties(property, value)
local armParts = {"LeftUpperArm", "LeftLowerArm", "LeftHand","RightUpperArm", "RightLowerArm", "RightHand"}
for _, partName in ipairs(armParts) do
game:GetService("Workspace").Ignore.FPSArms[partName][property] = value
end
end

ArmVisTab:AddToggle('ArmChams', { Text = 'enabled', Default = false }):AddColorPicker('ArmChamsColor', { Default = Color3.fromRGB(44, 0, 221), Title = 'Color' }):OnChanged(function(Value)
if Value == true then
elseif Value == false then
setArmProperties("Color", Color3.fromRGB(44, 0, 221))
setArmProperties("Material", "SmoothPlastic")
setArmProperties("TextureID", "")
end
end)
Options.ArmChamsColor:OnChanged(function(Value)
setArmProperties("Color", Value)
end)

ArmVisTab:AddDropdown('ArmChamsMaterial', {Values = { "ForceField"  },Default = 1,Multi = false,Text = 'arm material:'}):OnChanged(function(Value)
setArmProperties("Material", Value)
end)





local oldTick = tick()
local Camera = game:GetService("Workspace").CurrentCamera
local CharcaterMiddle = game:GetService("Workspace").Ignore.LocalCharacter.Middle
local Mouse = game.Players.LocalPlayer:GetMouse()

local Functions = {}
local Esp = {
	Settings = {
		Boxes = false,
		BoxesOutline = true,
		BoxesColor = Color3.fromRGB(44, 0, 221),
		BoxesOutlineColor = Color3.fromRGB(0, 0, 0),
		Sleeping = false,
		SleepingColor = Color3.fromRGB(44, 0, 221),
		Distances = false,
		DistanceColor = Color3.fromRGB(44, 0, 221),
		Armour = false,
		ArmourColor = Color3.fromRGB(44, 0, 221),
		Tool = false,
		ToolColor = Color3.fromRGB(44, 0, 221),
		Tracer = false,
		TracerColor = Color3.fromRGB(44, 0, 221),
		TracerThickness = 1,
		TracerTransparrency = 1,
		TracerFrom = "Bottom",
		ViewAngle = false,
		ViewAngleColor = Color3.fromRGB(44, 0, 221),
		ViewAngleThickness = 1,
		ViewAngleTransparrency = 1,
		OreDistances = false,
		OreDistanceColor = Color3.fromRGB(44, 0, 221),
		OreNames = false,
		OreNamesColor = Color3.fromRGB(44, 0, 221),
		OresRenderDistance = 1500,
		TextFont = 2,
		TextOutline = true,
		TextSize = 25,
		RenderDistance = 1500,
		TeamCheck = false,
		TargetSleepers = false,
		MinTextSize = 10,
	},
	Drawings = {},
	Connections = {},
	Players = {},
	Ores = {},
	StorageThings = {},
}
local Fonts = { ["UI"] = 0, ["System"] = 1, ["Plex"] = 2, ["Monospace"] = 3 }
local cache = {}
local Fov = {Settings={
    FovEnabled=true,
    FovColor=Color3.fromRGB(255,255,255),
    FovSize=90,
    FovFilled=false,
    FovTransparency=1,
    OutlineFovColor=Color3.fromRGB(0,0,0),
    RealFovSize=90,
    FovPosition="Screen",
    Snapline=true,
    SnaplineColor=Color3.fromRGB(255,255,255)
  }}
  local Combat = {Settings={
    SilentEnabled=true,
    SilentHitChance=100,
    SilentAimPart="Head",
    TeamCheck=true,
    SleeperCheck=true,
  }}
  local cache = {}
  
  --// Silent Aim -()
  function Functions:GetClosest()
    local closest,PlayerDistance,playerTable = nil,Combat.Settings.RenderDistance,nil
    for i,v in pairs(getupvalues(getrenv()._G.modules.Player.GetPlayerModel)[1]) do
      if v.model:FindFirstChild("HumanoidRootPart") and Combat.Settings.SleeperCheck == true and v.sleeping == nil then
        local Mouse = game.Players.LocalPlayer:GetMouse()
        local pos,OnScreen = Camera.WorldToViewportPoint(Camera, v.model:GetPivot().Position)
        local MouseMagnitude = (Vector2.new(pos.X, pos.Y) - Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)).Magnitude
        local PlayerDistance = (CharcaterMiddle:GetPivot().Position-v.model:GetPivot().Position).Magnitude
        if MouseMagnitude < Fov.Settings.FovSize and PlayerDistance <= Combat.Settings.RenderDistance and OnScreen == true then
          closest = v.model;PlayerDistance = PlayerDistance;playerTable=v
        end
      elseif v.model:FindFirstChild("HumanoidRootPart") and Combat.Settings.SleeperCheck == false then
        local Mouse = game.Players.LocalPlayer:GetMouse()
        local pos,OnScreen = Camera.WorldToViewportPoint(Camera, v.model:GetPivot().Position)
        local MouseMagnitude = (Vector2.new(pos.X, pos.Y) - Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)).Magnitude
        local PlayerDistance = (CharcaterMiddle:GetPivot().Position-v.model:GetPivot().Position).Magnitude
        if MouseMagnitude < Fov.Settings.FovSize and PlayerDistance <= Combat.Settings.RenderDistance and OnScreen == true then
          closest = v.model;PlayerDistance = PlayerDistance;playerTable=v
        end
      end
    end
    return closest,playerTable
  end
  function Functions:GetProjectileInfo()
    if getrenv()._G.modules.FPS.GetEquippedItem() == nil then return 0,0 end
    local mod = require(game:GetService("ReplicatedStorage").ItemConfigs[getrenv()._G.modules.FPS.GetEquippedItem().id])
    for i,v in pairs(mod) do
      if i == "ProjectileSpeed" or i == "ProjectileDrop" then
        return mod.ProjectileSpeed,mod.ProjectileDrop
      end
    end
    return 0,0
  end
  function Functions:Predict()
    local Prediction = Vector3.new(0,0,0)
    local Drop = Vector3.new(0,0,0)
    if Functions:GetClosest() ~= nil then
      local ps,pd = Functions:GetProjectileInfo()
      local Player,PlayerTable = Functions:GetClosest()
      local Velocity = PlayerTable.velocityVector
      local Distance = (CharcaterMiddle.Position - Player[Combat.Settings.SilentAimPart].Position).Magnitude
      if ps == 0 then
        ps = 500
      end
      if pd == 0 then
        pd = 1
      end
      local TimeOfFlight = Distance / ps
      newps = ps - 13 * ps ^ 2 * TimeOfFlight ^ 2
      TimeOfFlight += (Distance / newps)
      local dropTime = pd * TimeOfFlight ^ 2
      if Velocity and TimeOfFlight then
        Drop = Vector3.new(0,(dropTime * 20)*.4,0)
        Prediction = (Velocity * (TimeOfFlight*8)) * .70
      end
      Prediction = Prediction + Drop
    end
    return Prediction,Drop
  end
  
  --// Player ESP -()
  function Functions:Draw(Type,Propities)
    if not Type and not Propities then return end
    local drawing = Drawing.new(Type)
    for i,v in pairs(Propities) do
      drawing[i] = v
    end
    table.insert(Esp.Drawings,drawing)
    return drawing
  end
  function Esp:CreateEsp(PlayerTable)
    if not PlayerTable then return end
    local drawings = {}
    drawings.BoxOutline = Functions:Draw("Square",{Thickness=2,Filled=false,Transparency=1,ZIndex = -1,Visible=false});
    drawings.Box = Functions:Draw("Square",{Thickness=1,Filled=false,Transparency=1,Color=Esp.Settings.BoxesColor,Color=Esp.Settings.OtherBoxesColor,Color=Esp.Settings.OtherBoxesColorTeam,ZIndex = 2,Visible=false});
    drawings.BoxFilled = Functions:Draw("Square",{Thickness=1,Filled=true,Transparency=Esp.Settings.BoxesFilledTransparency,Color=Esp.Settings.BoxesFilledColor,ZIndex = 2,Visible=false});
    drawings.Sleeping = Functions:Draw("Text",{Text = "Nil",Font=Esp.Settings.TextFont,Size=Esp.Settings.TextSize,Center=true,Outline=Esp.Settings.TextOutline,Color = Esp.Settings.SleepingColor,Color = Esp.Settings.OtherSleepingColor,Color = Esp.Settings.OtherSleepingColorTeam,ZIndex = 2,Visible=false})
    drawings.Distance = Functions:Draw("Text",{Text = "[nil]",Font=Esp.Settings.TextFont,Size=Esp.Settings.TextSize,Center=true,Outline=Esp.Settings.TextOutline,Color = Esp.Settings.DistanceColor,Color = Esp.Settings.OtherDistanceColor,Color = Esp.Settings.OtherDistanceColorTeam,ZIndex = 2,Visible=false})
    drawings.Armour = Functions:Draw("Text",{Text = "",Font=Esp.Settings.TextFont,Size=Esp.Settings.TextSize,Center=true,Outline=Esp.Settings.TextOutline,Color = Esp.Settings.ArmourColor,Color = Esp.Settings.OtherArmourColor,Color = Esp.Settings.OtherArmourColorTeam,ZIndex = 2,Visible=false})
    drawings.Tool = Functions:Draw("Text",{Text = "Empty",Font=Esp.Settings.TextFont,Size=Esp.Settings.TextSize,Center=true,Outline=Esp.Settings.TextOutline,Color = Esp.Settings.ToolColor,Color = Esp.Settings.OtherToolColor,Color = Esp.Settings.OtherToolColorTeam,ZIndex = 2,Visible=false})
    drawings.ViewAngle = Functions:Draw("Line",{Thickness=Esp.Settings.ViewAngleThickness,Transparency=Esp.Settings.ViewAngleTransparrency,Color=Esp.Settings.ViewAngleColor,Color=Esp.Settings.OtherViewAngleColor,Color=Esp.Settings.OtherViewAngleColorTeam,ZIndex=2,Visible=false})
    drawings.HeadCircles = Functions:Draw("Circle",{Thickness=Esp.Settings.HeadCirclesThickness,Transparency=Esp.Settings.HeadCirclesTransparrency,Color=Esp.Settings.HeadCirclesColor,Color=Esp.Settings.OtherHeadCirclesColor,Color=Esp.Settings.OtherHeadCirclesColorTeam,ZIndex=2,Visible=false})
    drawings.Tracer = Functions:Draw("Line",{Thickness=Esp.Settings.TracerThickness,Transparency=1,Color=Esp.Settings.TracerColor,Color=Esp.Settings.OtherTracerColor,Color=Esp.Settings.OtherTracerColorTeam,ZIndex=2,Visible=false})
    drawings.Line1 = Functions:Draw("Line",{Thickness=Esp.Settings.CornerEspThickness,Transparency=1,Color=Esp.Settings.BoxesColor,ZIndex=2,Visible=false});drawings.Line2 = Functions:Draw("Line",{Thickness=Esp.Settings.CornerEspThickness,Transparency=1,Color=Esp.Settings.BoxesColor,ZIndex=2,Visible=false});drawings.Line3 = Functions:Draw("Line",{Thickness=Esp.Settings.CornerEspThickness,Transparency=1,Color=Esp.Settings.BoxesColor,ZIndex=2,Visible=false});drawings.Line4 = Functions:Draw("Line",{Thickness=Esp.Settings.CornerEspThickness,Transparency=1,Color=Esp.Settings.BoxesColor,ZIndex=2,Visible=false});drawings.Line5 = Functions:Draw("Line",{Thickness=Esp.Settings.CornerEspThickness,Transparency=1,Color=Esp.Settings.BoxesColor,ZIndex=2,Visible=false});drawings.Line6 = Functions:Draw("Line",{Thickness=Esp.Settings.CornerEspThickness,Transparency=1,Color=Esp.Settings.BoxesColor,ZIndex=2,Visible=false});drawings.Line7 = Functions:Draw("Line",{Thickness=Esp.Settings.CornerEspThickness,Transparency=1,Color=Esp.Settings.BoxesColor,ZIndex=2,Visible=false});drawings.Line8 = Functions:Draw("Line",{Thickness=Esp.Settings.CornerEspThickness,Transparency=1,Color=Esp.Settings.BoxesColor,ZIndex=2,Visible=false})
    drawings.PlayerTable = PlayerTable
    Esp.Players[PlayerTable.model] = drawings
  end
  function Esp:RemoveEsp(PlayerTable)
    if not PlayerTable and PlayerTable.model ~= nil then return end
    esp = Esp.Players[PlayerTable.model];
    if not esp then return end
    for i, v in pairs(esp) do
      if not type(v) == "table" then
        v:Remove();
      end
    end
    Esp.Players[PlayerTable.model] = nil;
  end
  function Esp:UpdateEsp()
    for i,v in pairs(Esp.Players) do
      local Character = i
      local Position,OnScreen = Camera:WorldToViewportPoint(Character:GetPivot().Position);
      local scale = 1 / (Position.Z * math.tan(math.rad(Camera.FieldOfView * 0.5)) * 2) * 100;
      local w,h = math.floor(40 * scale), math.floor(55 * scale);
      local x,y = math.floor(Position.X), math.floor(Position.Y);
      local Distance = (CharcaterMiddle:GetPivot().Position-Character:GetPivot().Position).Magnitude
      local BoxPosX,BoxPosY = math.floor(x - w * 0.5),math.floor(y - h * 0.5)
      local offsetCFrame = CFrame.new(0, 0, -4)
      local IsVisible = false
      if Character and Character:FindFirstChild("HumanoidRootPart") and Character:FindFirstChild("Head") and Character.Parent == game.Workspace then
        local TeamTag = Character.Head.Teamtag.Enabled
        local ccc,ttt = Functions:GetClosest()
        if OnScreen == true and Esp.Settings.Boxes == true and Distance <= Esp.Settings.RenderDistance then
          if Esp.Settings.TeamCheck == true and TeamTag == false then
            v.BoxOutline.Visible = Esp.Settings.BoxesOutline;v.Box.Visible = true;v.BoxFilled.Visible=Esp.Settings.BoxesFilled
          elseif Esp.Settings.TeamCheck == true and TeamTag == true then
            v.BoxOutline.Visible = false;v.Box.Visible = false;v.BoxFilled.Visible=false
          else
            v.BoxOutline.Visible = Esp.Settings.BoxesOutline;v.Box.Visible = true;v.BoxFilled.Visible=Esp.Settings.BoxesFilled
          end
          if Esp.Settings.TargetSleepers == true and v.PlayerTable.sleeping == true then
            v.BoxOutline.Visible = false;v.Box.Visible = false;v.BoxFilled.Visible = false
          end
          v.BoxOutline.Position = Vector2.new(BoxPosX,BoxPosY);v.BoxOutline.Size = Vector2.new(w,h)
          v.Box.Position = Vector2.new(BoxPosX,BoxPosY);v.Box.Size = Vector2.new(w,h)
          v.Box.Color = Esp.Settings.BoxesColor;v.BoxOutline.Color = Color3.fromRGB(0, 0, 0)
          v.BoxOutline.Transparency = 1
          v.BoxFilled.Position=Vector2.new(BoxPosX,BoxPosY);v.BoxFilled.Size=Vector2.new(w,h)
          v.BoxFilled.Transparency = Esp.Settings.BoxesFilledTransparency
          v.BoxFilled.Color = Esp.Settings.BoxesFilledColor
          if IsVisible == true then
            v.Box.Color = Color3.fromRGB(255,0,0);v.BoxOutline.Color=Esp.Settings.BoxesOutlineColor;v.BoxFilled.Color=Color3.fromRGB(0,0,0)
          else
            v.Box.Color = Esp.Settings.BoxesColor;v.BoxOutline.Color = Esp.Settings.BoxesOutlineColor;v.BoxFilled.Color=Esp.Settings.BoxesFilledColor
          end
          if Esp.Settings.HighlightTarget and Character == ccc then
            v.Box.Color = Esp.Settings.HighlightTargetColor
          else
            v.Box.Color = Esp.Settings.BoxesColor;
          end
          if v.PlayerTable.sleeping == true then v.Box.Color = Esp.Settings.OtherBoxesColor end
          if TeamTag == true then v.Sleeping.Text = "Friendly" end
          if TeamTag == true then v.Box.Color = Esp.Settings.OtherBoxesColorTeam end
        else
          v.BoxOutline.Visible = false;v.Box.Visible = false;v.BoxFilled.Visible = false;
        end
        if OnScreen == true and Esp.Settings.CornerBoxes == true and Distance <= Esp.Settings.RenderDistance then
          if Esp.Settings.TeamCheck == true and TeamTag == false then
            v.BoxFilled.Visible=Esp.Settings.BoxesFilled
            v.Line1.Visible=Esp.Settings.CornerBoxes;v.Line2.Visible=Esp.Settings.CornerBoxes;v.Line3.Visible=Esp.Settings.CornerBoxes;v.Line4.Visible=Esp.Settings.CornerBoxes;v.Line5.Visible=Esp.Settings.CornerBoxes;v.Line6.Visible=Esp.Settings.CornerBoxes;v.Line7.Visible=Esp.Settings.CornerBoxes;v.Line8.Visible=Esp.Settings.CornerBoxes
          elseif Esp.Settings.TeamCheck == true and TeamTag == true then
            v.Line1.Visible=false;v.Line2.Visible=false;v.Line3.Visible=false;v.Line4.Visible=false;v.Line5.Visible=false;v.Line6.Visible=false;v.Line7.Visible=false;v.Line8.Visible=false
            v.BoxFilled.Visible=false
          else
            v.BoxFilled.Visible=Esp.Settings.BoxesFilled
            v.Line1.Visible=Esp.Settings.CornerBoxes;v.Line2.Visible=Esp.Settings.CornerBoxes;v.Line3.Visible=Esp.Settings.CornerBoxes;v.Line4.Visible=Esp.Settings.CornerBoxes;v.Line5.Visible=Esp.Settings.CornerBoxes;v.Line6.Visible=Esp.Settings.CornerBoxes;v.Line7.Visible=Esp.Settings.CornerBoxes;v.Line8.Visible=Esp.Settings.CornerBoxes
          end
          if Esp.Settings.TargetSleepers == true and v.PlayerTable.sleeping == true then
            v.Line1.Visible=false;v.Line2.Visible=false;v.Line3.Visible=false;v.Line4.Visible=false;v.Line5.Visible=false;v.Line6.Visible=false;v.Line7.Visible=false;v.Line8.Visible=false
            v.BoxFilled.Visible = false
          end
          v.Line1.From=Vector2.new(BoxPosX,BoxPosY);v.Line1.To=Vector2.new((BoxPosX+w/4),BoxPosY) --Top Left Top
          v.Line2.From=Vector2.new(BoxPosX+w,BoxPosY);v.Line2.To=Vector2.new((BoxPosX+w)-w/4,BoxPosY) -- Top Right Top
          v.Line3.From=Vector2.new(BoxPosX,BoxPosY+h);v.Line3.To=Vector2.new((BoxPosX+w/4),BoxPosY+h) -- Bottom Left Bottom
          v.Line4.From=Vector2.new(BoxPosX+w,BoxPosY+h);v.Line4.To=Vector2.new((BoxPosX+w)-w/4,BoxPosY+h) --Bottom Right Bottom
          v.Line5.From=Vector2.new(BoxPosX,BoxPosY);v.Line5.To=Vector2.new(BoxPosX,BoxPosY+h/8) --Top Left Down
          v.Line6.From=Vector2.new(BoxPosX,BoxPosY+h);v.Line6.To=Vector2.new(BoxPosX,(BoxPosY+h)-h/8) --Bottom Left Up
          v.Line7.From=Vector2.new(BoxPosX+w,BoxPosY+h);v.Line7.To=Vector2.new(BoxPosX+w,(BoxPosY+h)-h/8) --Bottom Right Up
          v.Line8.From=Vector2.new(BoxPosX+w,BoxPosY);v.Line8.To=Vector2.new(BoxPosX+w,BoxPosY+h/8) --Top Right Down
          v.BoxFilled.Position=Vector2.new(BoxPosX,BoxPosY);v.BoxFilled.Size=Vector2.new(w,h)
          v.BoxFilled.Transparency = Esp.Settings.BoxesFilledTransparency
          if IsVisible == true then
            v.Line1.Color=Color3.fromRGB(255,0,0);v.Line2.Color=Color3.fromRGB(255,0,0);v.Line3.Color=Color3.fromRGB(255,0,0);v.Line4.Color=Color3.fromRGB(255,0,0);v.Line5.Color=Color3.fromRGB(255,0,0);v.Line6.Color=Color3.fromRGB(255,0,0);v.Line7.Color=Color3.fromRGB(255,0,0);v.Line8.Color=Color3.fromRGB(255,0,0)
            v.BoxFilled.Color=Color3.fromRGB(255,0,0)
          else
            v.Line1.Color=Esp.Settings.BoxesColor;v.Line2.Color=Esp.Settings.BoxesColor;v.Line3.Color=Esp.Settings.BoxesColor;v.Line4.Color=Esp.Settings.BoxesColor;v.Line5.Color=Esp.Settings.BoxesColor;v.Line6.Color=Esp.Settings.BoxesColor;v.Line7.Color=Esp.Settings.BoxesColor;v.Line8.Color=Esp.Settings.BoxesColor
            v.BoxFilled.Color=Esp.Settings.BoxesFilledColor
          end
          if Esp.Settings.HighlightTarget and Character == ccc then
            v.Line1.Color = Esp.Settings.HighlightTargetColor
            v.Line2.Color = Esp.Settings.HighlightTargetColor
            v.Line3.Color = Esp.Settings.HighlightTargetColor
            v.Line4.Color = Esp.Settings.HighlightTargetColor
            v.Line5.Color = Esp.Settings.HighlightTargetColor
            v.Line6.Color = Esp.Settings.HighlightTargetColor
            v.Line7.Color = Esp.Settings.HighlightTargetColor
            v.Line8.Color = Esp.Settings.HighlightTargetColor
          else
            v.Line1.Color = Esp.Settings.BoxesColor
            v.Line2.Color = Esp.Settings.BoxesColor
            v.Line3.Color = Esp.Settings.BoxesColor
            v.Line4.Color = Esp.Settings.BoxesColor
            v.Line5.Color = Esp.Settings.BoxesColor
            v.Line6.Color = Esp.Settings.BoxesColor
            v.Line7.Color = Esp.Settings.BoxesColor
            v.Line8.Color = Esp.Settings.BoxesColor
          end
          if v.PlayerTable.sleeping == true then
            v.Line1.Color = Esp.Settings.OtherBoxesColor;v.Line2.Color = Esp.Settings.OtherBoxesColor;v.Line3.Color = Esp.Settings.OtherBoxesColor;v.Line4.Color = Esp.Settings.OtherBoxesColor;v.Line5.Color = Esp.Settings.OtherBoxesColor;v.Line6.Color = Esp.Settings.OtherBoxesColor;v.Line7.Color = Esp.Settings.OtherBoxesColor;v.Line8.Color = Esp.Settings.OtherBoxesColor
          end
          if TeamTag == true then
            v.Line1.Color = Esp.Settings.OtherBoxesColorTeam;v.Line2.Color = Esp.Settings.OtherBoxesColorTeam;v.Line3.Color = Esp.Settings.OtherBoxesColorTeam;v.Line4.Color = Esp.Settings.OtherBoxesColorTeam;v.Line5.Color = Esp.Settings.OtherBoxesColorTeam;v.Line6.Color = Esp.Settings.OtherBoxesColorTeam;v.Line7.Color = Esp.Settings.OtherBoxesColorTeam;v.Line8.Color = Esp.Settings.OtherBoxesColorTeam
          end
        else
          v.Line1.Visible=false;v.Line2.Visible=false;v.Line3.Visible=false;v.Line4.Visible=false;v.Line5.Visible=false;v.Line6.Visible=false;v.Line7.Visible=false;v.Line8.Visible=false;v.BoxFilled.Visible = false
        end
        if OnScreen == true and Esp.Settings.Sleeping == true and Distance <= Esp.Settings.RenderDistance then
          if Character.Head.Nametag.tag.Text ~= "" then
            v.Sleeping.Text = Character:FindFirstChild("Head").Nametag.tag.Text
          else
            v.Sleeping.Text = "Enemy"
            if TeamTag == true then v.Sleeping.Text = "Friendly" end
            if v.PlayerTable.sleeping == true then v.Sleeping.Text = "Sleeping" end
          end
          if Esp.Settings.TeamCheck == true and TeamTag == false then  v.Sleeping.Visible = true elseif Esp.Settings.TeamCheck == true and TeamTag == true then v.Sleeping.Visible = false else v.Sleeping.Visible = true end
          if Esp.Settings.TargetSleepers == true and v.PlayerTable.sleeping == true then v.Sleeping.Visible = false end
          v.Sleeping.Outline=Esp.Settings.TextOutline;v.Sleeping.Color=Esp.Settings.SleepingColor;v.Sleeping.Size=math.max(math.min(math.abs(Esp.Settings.TextSize*scale),Esp.Settings.TextSize),Esp.Settings.MinTextSize);v.Sleeping.Color = Esp.Settings.SleepingColor;v.Sleeping.Font=Esp.Settings.TextFont;v.Sleeping.Position = Vector2.new(x,math.floor(y-h*0.5-v.Sleeping.TextBounds.Y))
          if Esp.Settings.HighlightTarget and Character == ccc then
            v.Sleeping.Color = Esp.Settings.HighlightTargetColor
          else
            v.Sleeping.Color = Esp.Settings.SleepingColor;
          end
          if v.PlayerTable.sleeping == true then v.Sleeping.Color = Esp.Settings.OtherSleepingColor end
          if TeamTag == true then v.Sleeping.Color = Esp.Settings.OtherSleepingColorTeam end
        else
          v.Sleeping.Visible=false
        end
        if OnScreen == true and Esp.Settings.Distances == true and Distance <= Esp.Settings.RenderDistance then
          if Esp.Settings.TeamCheck == true and TeamTag == false then v.Distance.Visible = true elseif Esp.Settings.TeamCheck == true and TeamTag == true then v.Distance.Visible = false else v.Distance.Visible = true end
          if Esp.Settings.TargetSleepers == true and v.PlayerTable.sleeping == true then v.Distance.Visible = false end
          v.Distance.Outline=Esp.Settings.TextOutline;v.Distance.Size = math.max(math.min(math.abs(Esp.Settings.TextSize*scale),Esp.Settings.TextSize),Esp.Settings.MinTextSize);v.Distance.Position=Vector2.new(x,math.floor(y+h*0.5));v.Distance.Color = Esp.Settings.DistanceColor;v.Distance.Text = tostring("["..math.floor(Distance)).."]";v.Distance.Font=Esp.Settings.TextFont
          if Esp.Settings.HighlightTarget and Character == ccc then
            v.Distance.Color = Esp.Settings.HighlightTargetColor
          else
            v.Distance.Color = Esp.Settings.DistanceColor;
          end
          if v.PlayerTable.sleeping == true then v.Distance.Color = Esp.Settings.OtherDistanceColor end
          if TeamTag == true then v.Distance.Color = Esp.Settings.OtherDistanceColorTeam end
        else
          v.Distance.Visible = false
        end
        if OnScreen == true and Esp.Settings.Tool == true and Distance <= Esp.Settings.RenderDistance then
          if Esp.Settings.TeamCheck == true and TeamTag == false then v.Tool.Visible = true elseif Esp.Settings.TeamCheck == true and TeamTag == true then v.Tool.Visible = false else v.Tool.Visible = true end
          if Esp.Settings.TargetSleepers == true and v.PlayerTable.sleeping == true then v.Tool.Visible = false end
          if Esp.Settings.Tool == true then v.Tool.Position=Vector2.new(x, math.floor(y+h*0.5)+v.Tool.TextBounds.Y) else v.Tool.Position=Vector2.new(x,math.floor(y+h*0.5)); end
          v.Tool.Text=Esp:CheckTools(v.PlayerTable);v.Tool.Outline=Esp.Settings.TextOutline;v.Tool.Size=math.max(math.min(math.abs(Esp.Settings.TextSize*scale),Esp.Settings.TextSize),Esp.Settings.MinTextSize);v.Tool.Color=Esp.Settings.ToolColor;v.Tool.Font=Esp.Settings.TextFont
          if Esp.Settings.HighlightTarget and Character == ccc then
            v.Tool.Color = Esp.Settings.HighlightTargetColor
          else
            v.Tool.Color = Esp.Settings.ToolColor;
          end
          if v.PlayerTable.sleeping == true then v.Tool.Color = Esp.Settings.OtherToolColor end
          if TeamTag == true then v.Tool.Color = Esp.Settings.OtherToolColorTeam end
        else
          v.Tool.Visible = false
        end
        local armorFolder = Character.Armor:FindFirstChildOfClass("Folder")
        if OnScreen == true and Esp.Settings.Armour == true and Distance <= Esp.Settings.RenderDistance and armorFolder then
          local armorName = armorFolder.Name
          if armorName == "WoodHelmet" or armorName == "WoodChestplate" or armorName == "WoodLeggings" then
            v.Armour.Text = "Wood Gear"
          elseif armorName == "RiotHelmet" or armorName == "RiotChestplate" or armorName == "RiotLeggings" then
            v.Armour.Text = "Riot Gear"
          elseif armorName == "IronHelmet" or armorName == "IronChestplate" or armorName == "IronLeggings" then
            v.Armour.Text = "Iron Gear"
          elseif armorName == "SteelHelmet" or armorName == "SteelChestplate" or armorName == "SteelLeggings" then
            v.Armour.Text = "Steel Gear"
          else
            v.Armour.Text = ""
          end
          if Esp.Settings.TeamCheck == true and TeamTag == false then v.Armour.Visible = true elseif Esp.Settings.TeamCheck == true and TeamTag == true then v.Armour.Visible = false else v.Armour.Visible = true end
          if Esp.Settings.TargetSleepers == true and v.PlayerTable.sleeping == true then v.Armour.Visible = false end
          v.Armour.Outline=Esp.Settings.TextOutline;v.Armour.Size = math.max(math.min(math.abs(Esp.Settings.TextSize*scale),Esp.Settings.TextSize),Esp.Settings.MinTextSize);v.Armour.Position=Vector2.new(math.floor(BoxPosX+w+v.Armour.TextBounds.X*1.30*0.5),BoxPosY+v.Armour.TextBounds.Y*1.85*0.5-((v.Armour.TextBounds.Y*2)*0.5));v.Armour.Color = Esp.Settings.ArmourColor;v.Armour.Font=Esp.Settings.TextFont
          v.Armour.Color = Esp.Settings.HighlightTargetColor
          if Esp.Settings.HighlightTarget and Character == ccc then
            v.Armour.Color = Esp.Settings.HighlightTargetColor
          else
            v.Armour.Color = Esp.Settings.ArmourColor;
          end
          if v.PlayerTable.sleeping == true then v.Armour.Color = Esp.Settings.OtherArmourColor end
          if TeamTag == true then v.Armour.Color = Esp.Settings.OtherArmourColorTeam end
        else
          v.Armour.Visible = false;
        end
        if OnScreen == true and Esp.Settings.Tracer == true and Distance <= Esp.Settings.RenderDistance then
          if Esp.Settings.TeamCheck == true and TeamTag == false then v.Tracer.Visible = true elseif Esp.Settings.TeamCheck == true and TeamTag == true then v.Tracer.Visible = false else v.Tracer.Visible = true end
          if Esp.Settings.TargetSleepers == true and v.PlayerTable.sleeping == true then v.Tracer.Visible = false end
          v.Tracer.Color = Esp.Settings.TracerColor;v.Tracer.Thickness=Esp.Settings.TracerThickness;v.Transparency=Esp.Settings.TracerTransparrency;
          if Esp.Settings.TracerFrom == "Bottom" then
            v.Tracer.From = Vector2.new(Camera.ViewportSize.X/2,Camera.ViewportSize.Y)
            v.Tracer.To = Vector2.new(x,y+h*0.5)
          elseif Esp.Settings.TracerFrom == "Middle" then
            v.Tracer.From = Vector2.new(Camera.ViewportSize.X/2,Camera.ViewportSize.Y/2)
            v.Tracer.To = Vector2.new(x,y)
          elseif Esp.Settings.TracerFrom == "Top" then
            v.Tracer.From = Vector2.new(Camera.ViewportSize.X / 2, 0)
            v.Tracer.To = Vector2.new(x,y-h*0.5)
          else
            v.Tracer.From = Vector2.new(Camera.ViewportSize.X/2,Camera.ViewportSize.Y/Camera.ViewportSize.Y)
            if Esp.Settings.Sleeping == true then
              v.Tracer.To = Vector2.new(x,(y-h)-v.Sleeping.TextBounds.Y*0.5)
            else
              v.Tracer.From = Vector2.new(Camera.ViewportSize.X/2,Camera.ViewportSize.Y)
              v.Tracer.To = Vector2.new(x,y-h*0.5)
            end
          end
          if Esp.Settings.HighlightTarget and Character == ccc then
            v.Tracer.Color = Esp.Settings.HighlightTargetColor
          else
            v.Tracer.Color = Esp.Settings.TracerColor;
          end
          if v.PlayerTable.sleeping == true then v.Tracer.Color = Esp.Settings.OtherTracerColor end
          if TeamTag == true then v.Tracer.Color = Esp.Settings.OtherTracerColorTeam end
        else
          v.Tracer.Visible = false
        end
        if OnScreen == true and Esp.Settings.ViewAngle == true and Distance <= Esp.Settings.RenderDistance then
          if Esp.Settings.TeamCheck == true and TeamTag == false then v.ViewAngle.Visible = true elseif Esp.Settings.TeamCheck == true and TeamTag == true then v.ViewAngle.Visible = false else v.ViewAngle.Visible = true end
          if Esp.Settings.TargetSleepers == true and v.PlayerTable.sleeping == true then v.ViewAngle.Visible = false end
          v.ViewAngle.Color = Esp.Settings.ViewAngleColor;v.ViewAngle.Thickness=Esp.Settings.ViewAngleThickness;v.Transparency=Esp.Settings.ViewAngleTransparrency;
          local headpos = Camera:WorldToViewportPoint(Character.Head.Position)
          local offsetCFrame = CFrame.new(0, 0, -4)
          v.ViewAngle.From = Vector2.new(headpos.X, headpos.Y)
          local value = math.clamp(1/Distance*100, 0.1, 1)
          local dir = Character.Head.CFrame:ToWorldSpace(offsetCFrame)
          offsetCFrame = offsetCFrame * CFrame.new(0, 0, 0.4)
          local dirpos = Camera:WorldToViewportPoint(Vector3.new(dir.X, dir.Y, dir.Z))
          if OnScreen == true then
            v.ViewAngle.To = Vector2.new(dirpos.X, dirpos.Y)
            offsetCFrame = CFrame.new(0, 0, -4)
          end
          if Esp.Settings.HighlightTarget and Character == ccc then
            v.ViewAngle.Color = Esp.Settings.HighlightTargetColor
          else
            v.ViewAngle.Color = Esp.Settings.ViewAngleColor;
          end
          if v.PlayerTable.sleeping == true then v.ViewAngle.Color = Esp.Settings.OtherViewAngleColor end
          if TeamTag == true then v.ViewAngle.Color = Esp.Settings.OtherViewAngleColorTeam end
        else
          v.ViewAngle.Visible = false
        end
        if OnScreen == true and Esp.Settings.HeadCircles == true and Distance <= Esp.Settings.RenderDistance then
          if Esp.Settings.TeamCheck == true and TeamTag == false then v.HeadCircles.Visible = true elseif Esp.Settings.TeamCheck == true and TeamTag == true then v.HeadCircles.Visible = false else v.HeadCircles.Visible = true end
          if Esp.Settings.TargetSleepers == true and v.PlayerTable.sleeping == true then v.HeadCircles.Visible = false end
          v.HeadCircles.Color = Esp.Settings.HeadCirclesColor;v.HeadCircles.Thickness=Esp.Settings.HeadCirclesThickness;v.Transparency=Esp.Settings.HeadCirclesTransparrency;
          local headpos = Camera:WorldToViewportPoint(Character.Head.Position)
          local Position,OnScreen = Camera:WorldToViewportPoint(Character:FindFirstChild("HumanoidRootPart").Position);
          if OnScreen == true then
            v.HeadCircles.Position = Vector2.new(headpos.X, headpos.Y)
            v.HeadCircles.Radius = 3
            v.HeadCircles.NumSides = 18
          end
          if Esp.Settings.HighlightTarget and Character == ccc then
            v.HeadCircles.Color = Esp.Settings.HighlightTargetColor
          else
            v.HeadCircles.Color = Esp.Settings.HeadCirclesColor;
          end
          if v.PlayerTable.sleeping == true then v.HeadCircles.Color = Esp.Settings.OtherHeadCirclesColor end
          if TeamTag == true then v.HeadCircles.Color = Esp.Settings.OtherHeadCirclesColorTeam end
        else
          v.HeadCircles.Visible = false
        end
      else
        v.Box.Visible=false;
        v.BoxOutline.Visible=false;
        v.BoxFilled.Visible=false;
        v.Tool.Visible=false;
        v.Armour.Visible=false;
        v.Distance.Visible=false;
        v.Sleeping.Visible=false;
        v.ViewAngle.Visible=false;
        v.HeadCircles.Visible=false;
        v.Tracer.Visible=false;
        v.Line1.Visible=false;v.Line2.Visible=false;v.Line3.Visible=false;v.Line4.Visible=false;v.Line5.Visible=false;v.Line6.Visible=false;v.Line7.Visible=false;v.Line8.Visible=false
      end
    end
  end
  local FovCircle = Functions:Draw("Circle",{Filled=Fov.Settings.FovFilled,Color=Fov.Settings.FovColor,Radius=Fov.Settings.FovSize,NumSides=64,Thickness=1,Transparency=Fov.Settings.FovTransparency,ZIndex=3,Visible=false})
  local FovCircleOutline = Functions:Draw("Circle",{Filled=Fov.Settings.FovOutlineFilled,Color=Fov.Settings.FovOutlineColor,Radius=Fov.Settings.FovOutlineSize,NumSides=64,Thickness=2.6,Transparency=0.28,ZIndex=2.98,Visible=false})
  local FovSnapline = Functions:Draw("Line",{Transparency=1,Thickness=1,Visible=false})
  local CircleLine = Functions:Draw("Circle",{Color=Fov.Settings.CircleLineColor,Radius=6,NumSides=18,Thickness=1,Transparency=Fov.Settings.FovTransparency,Visible=false})
  local PlayerUpdater = game:GetService("RunService").RenderStepped
  local PlayerConnection = PlayerUpdater:Connect(function()
  Esp:UpdateEsp()
  end)
  for i, v in pairs(getupvalues(getrenv()._G.modules.Player.GetPlayerModel)[1]) do
    if not table.find(cache,v) then
      table.insert(cache,v)
      Esp:CreateEsp(v)
    end
  end
  game:GetService("Workspace").ChildAdded:Connect(function(child)
  if child:FindFirstChild("HumanoidRootPart") then
    for i, v in pairs(getupvalues(getrenv()._G.modules.Player.GetPlayerModel)[1]) do
      if not table.find(cache,v) then
        table.insert(cache,v)
        Esp:CreateEsp(v)
      end
    end
  end
  end)
function Functions:Draw(Type, Propities)
	if not Type and not Propities then
		return
	end
	local drawing = Drawing.new(Type)
	for i, v in pairs(Propities) do
		drawing[i] = v
	end
	table.insert(Esp.Drawings, drawing)
	return drawing
end
function Functions:GetToolNames()
	tbl = {}
	for i, v in pairs(game:GetService("ReplicatedStorage").HandModels:GetChildren()) do
		if not table.find(tbl, v.Name) then
			table.insert(tbl, v.Name)
		end
	end
	return tbl
end
function Esp:CheckTools(PlayerTable)
	if not PlayerTable then
		return
	end
	if PlayerTable.equippedItem and table.find(Functions:GetToolNames(), PlayerTable["equippedItem"].id) then
		return tostring(PlayerTable["equippedItem"].id)
	elseif
		PlayerTable.handModel
		and PlayerTable.handModel.Name
		and string.find(PlayerTable.handModel.Name, "Hammer")
	then
		return PlayerTable["handModel"].Name
	else
		return "Empty"
	end
end
function Esp:CreateEsp(PlayerTable)
	if not PlayerTable then
		return
	end
	local drawings = {}
	drawings.BoxOutline = Functions:Draw(
		"Square",
		{
			Thickness = 2,
			Filled = false,
			Transparency = 1,
			Color = Esp.Settings.BoxesOutlineColor,
			Visible = false,
			ZIndex = -1,
			Visible = false,
		}
	)
	drawings.Box = Functions:Draw(
		"Square",
		{ Thickness = 1, Filled = false, Transparency = 1, Color = Esp.Settings.BoxesColor, Visible = false, ZIndex = 2, Visible = false }
	)
	drawings.Sleeping = Functions:Draw(
		"Text",
		{
			Text = "Nil",
			Font = Esp.Settings.TextFont,
			Size = Esp.Settings.TextSize,
			Center = true,
			Outline = Esp.Settings.TextOutline,
			Color = Esp.Settings.SleepingColor,
			ZIndex = 2,
			Visible = false,
		}
	)
	drawings.Armour = Functions:Draw(
		"Text",
		{
			Text = "Naked",
			Font = Esp.Settings.TextFont,
			Size = Esp.Settings.TextSize,
			Center = false,
			Outline = Esp.Settings.TextOutline,
			Color = Esp.Settings.ArmourColor,
			ZIndex = 2,
			Visible = false,
		}
	)
	drawings.Tool = Functions:Draw(
		"Text",
		{
			Text = "Nothing",
			Font = Esp.Settings.TextFont,
			Size = Esp.Settings.TextSize,
			Center = false,
			Outline = Esp.Settings.TextOutline,
			Color = Esp.Settings.ToolColor,
			ZIndex = 2,
			Visible = false,
		}
	)
	drawings.ViewAngle = Functions:Draw(
		"Line",
		{
			Thickness = Esp.Settings.ViewAngleThickness,
			Transparency = Esp.Settings.ViewAngleTransparrency,
			Color = Esp.Settings.ViewAngleColor,
			ZIndex = 2,
			Visible = false,
		}
	)
	drawings.Tracer = Functions:Draw(
		"Line",
		{ Thickness = Esp.Settings.TracerThickness, Transparency = 1, Color = Esp.Settings.TracerColor, ZIndex = 2, Visible = false }
	)
	drawings.PlayerTable = PlayerTable
	Esp.Players[PlayerTable.model] = drawings
end
function Esp:RemoveEsp(PlayerTable)
	if not PlayerTable and PlayerTable.model ~= nil then
		return
	end
	esp = Esp.Players[PlayerTable.model]
	if not esp then
		return
	end
	for i, v in pairs(esp) do
		if not type(v) == "table" then
			v:Remove()
		end
	end
	Esp.Players[PlayerTable.model] = nil
end

function Esp:UpdateEsp()
	for i, v in pairs(Esp.Players) do
		local Character = i
		local Position, OnScreen = Camera:WorldToViewportPoint(Character:GetPivot().Position)
		local scale = 1 / (Position.Z * math.tan(math.rad(Camera.FieldOfView * 0.5)) * 2) * 100
		local w, h = math.floor(40 * scale), math.floor(55 * scale)
		local x, y = math.floor(Position.X), math.floor(Position.Y)
		local Distance = (CharcaterMiddle:GetPivot().Position - Character:GetPivot().Position).Magnitude
		local BoxPosX, BoxPosY = math.floor(x - w * 0.5), math.floor(y - h * 0.5)
		local offsetCFrame = CFrame.new(0, 0, -4)
		if Character and Character:FindFirstChild("HumanoidRootPart") and Character:FindFirstChild("Head") then
			local TeamTag = Character.Head.Teamtag.Enabled
			if OnScreen == true and Esp.Settings.Boxes == true and Distance <= Esp.Settings.RenderDistance then
				if Esp.Settings.TeamCheck == true and TeamTag == false then
					v.BoxOutline.Visible = Esp.Settings.BoxesOutline
					v.Box.Visible = true
				elseif Esp.Settings.TeamCheck == true and TeamTag == true then
					v.BoxOutline.Visible = false
					v.Box.Visible = false
				else
					v.BoxOutline.Visible = Esp.Settings.BoxesOutline
					v.Box.Visible = true
				end
				if Esp.Settings.TargetSleepers == true and v.PlayerTable.sleeping == true then
					v.BoxOutline.Visible = false
					v.Box.Visible = false
				end
				v.BoxOutline.Position = Vector2.new(BoxPosX, BoxPosY)
				v.BoxOutline.Size = Vector2.new(w, h)
				v.Box.Position = Vector2.new(BoxPosX, BoxPosY)
				v.Box.Size = Vector2.new(w, h)
				v.Box.Color = Esp.Settings.BoxesColor
				v.BoxOutline.Color = Esp.Settings.BoxesOutlineColor
			else
				v.BoxOutline.Visible = false
				v.Box.Visible = false
			end
			if OnScreen == true and Esp.Settings.Sleeping == true and Distance <= Esp.Settings.RenderDistance then
				if v.PlayerTable.sleeping == true then
					v.Sleeping.Text = "Sleeping"
				else
					v.Sleeping.Text = "Awake"
				end
				if Esp.Settings.TeamCheck == true and TeamTag == false then
					v.Sleeping.Visible = true
				elseif Esp.Settings.TeamCheck == true and TeamTag == true then
					v.Sleeping.Visible = false
				else
					v.Sleeping.Visible = true
				end
				if Esp.Settings.TargetSleepers == true and v.PlayerTable.sleeping == true then
					v.Sleeping.Visible = false
				end
				v.Sleeping.Outline = Esp.Settings.TextOutline
				v.Sleeping.Color = Esp.Settings.SleepingColor
				v.Sleeping.Size = math.max(
					math.min(math.abs(Esp.Settings.TextSize * scale), Esp.Settings.TextSize),
					Esp.Settings.MinTextSize
				)
				v.Sleeping.Color = Esp.Settings.SleepingColor
				v.Sleeping.Font = Esp.Settings.TextFont
				v.Sleeping.Position = Vector2.new(x, math.floor(y - h * 0.5 - v.Sleeping.TextBounds.Y))
			else
				v.Sleeping.Visible = false
			end
			if OnScreen == true and Esp.Settings.Distances == true and Distance <= Esp.Settings.RenderDistance then
				if Esp.Settings.TeamCheck == true and TeamTag == false then
					v.Sleeping.Visible = true
				elseif Esp.Settings.TeamCheck == true and TeamTag == true then
					v.Sleeping.Visible = false
				else
					v.Sleeping.Visible = true
				end
				if Esp.Settings.TargetSleepers == true and v.PlayerTable.sleeping == true then
					v.Sleeping.Visible = false
				end

				if Esp.Settings.Sleeping == false then
					v.Sleeping.Text = math.floor(Distance) .. "s"
				else
					v.Sleeping.Text = v.Sleeping.Text .. " | " .. math.floor(Distance) .. "s"
				end
				v.Sleeping.Outline = Esp.Settings.TextOutline
				v.Sleeping.Color = Esp.Settings.SleepingColor
				v.Sleeping.Size = math.max(
					math.min(math.abs(Esp.Settings.TextSize * scale), Esp.Settings.TextSize),
					Esp.Settings.MinTextSize
				)
				v.Sleeping.Color = Esp.Settings.SleepingColor
				v.Sleeping.Font = Esp.Settings.TextFont
				v.Sleeping.Position = Vector2.new(x, math.floor(y - h * 0.5 - v.Sleeping.TextBounds.Y))
			else
				v.Sleeping.Visible = false
			end
			if OnScreen == true and Esp.Settings.Tool == true and Distance <= Esp.Settings.RenderDistance then
				if Esp.Settings.TeamCheck == true and TeamTag == false then
					v.Tool.Visible = true
				elseif Esp.Settings.TeamCheck == true and TeamTag == true then
					v.Tool.Visible = false
				else
					v.Tool.Visible = true
				end
				if Esp.Settings.TargetSleepers == true and v.PlayerTable.sleeping == true then
					v.Tool.Visible = false
				end
				v.Tool.Position = Vector2.new(
					math.floor((BoxPosX + w) + v.Tool.TextBounds.X / 10),
					BoxPosY + v.Tool.TextBounds.Y * 1.55 * 0.5 - ((v.Tool.TextBounds.Y * 2) * 0.5) + v.Tool.TextBounds.Y
				)
				v.Tool.Text = Esp:CheckTools(v.PlayerTable)
				v.Tool.Outline = Esp.Settings.TextOutline
				v.Tool.Size = math.max(
					math.min(math.abs(Esp.Settings.TextSize * scale), Esp.Settings.TextSize),
					Esp.Settings.MinTextSize
				)
				v.Tool.Color = Esp.Settings.ToolColor
				v.Tool.Font = Esp.Settings.TextFont
			else
				v.Tool.Visible = false
			end
			if OnScreen == true and Esp.Settings.Armour == true and Distance <= Esp.Settings.RenderDistance then
				if Character.Armor:FindFirstChildOfClass("Folder") then
					v.Armour.Text = "Armoured"
				else
					v.Armour.Text = "Naked"
				end
				if Esp.Settings.TeamCheck == true and TeamTag == false then
					v.Armour.Visible = true
				elseif Esp.Settings.TeamCheck == true and TeamTag == true then
					v.Armour.Visible = false
				else
					v.Armour.Visible = true
				end
				if Esp.Settings.TargetSleepers == true and v.PlayerTable.sleeping == true then
					v.Armour.Visible = false
				end
				v.Armour.Outline = Esp.Settings.TextOutline
				v.Armour.Size = math.max(
					math.min(math.abs(Esp.Settings.TextSize * scale), Esp.Settings.TextSize),
					Esp.Settings.MinTextSize
				)
				v.Armour.Position = Vector2.new(
					math.floor((BoxPosX + w) + v.Armour.TextBounds.X / 10),
					BoxPosY + v.Armour.TextBounds.Y * 1.55 * 0.5 - ((v.Armour.TextBounds.Y * 2) * 0.5)
				)
				v.Armour.Color = Esp.Settings.ArmourColor
				v.Armour.Font = Esp.Settings.TextFont
			else
				v.Armour.Visible = false
			end
			if OnScreen == true and Esp.Settings.Tracer == true and Distance <= Esp.Settings.RenderDistance then
				if Esp.Settings.TeamCheck == true and TeamTag == false then
					v.Tracer.Visible = true
				elseif Esp.Settings.TeamCheck == true and TeamTag == true then
					v.Tracer.Visible = false
				else
					v.Tracer.Visible = true
				end
				if Esp.Settings.TargetSleepers == true and v.PlayerTable.sleeping == true then
					v.Tracer.Visible = false
				end
				v.Tracer.Color = Esp.Settings.TracerColor
				v.Tracer.Thickness = Esp.Settings.TracerThickness
				v.Transparency = Esp.Settings.TracerTransparrency
				if Esp.Settings.TracerFrom == "Bottom" then
					v.Tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
					v.Tracer.To = Vector2.new(x, y + h * 0.5)
				elseif Esp.Settings.TracerFrom == "Middle" then
					v.Tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
					v.Tracer.To = Vector2.new(x, y)
				else
					v.Tracer.From =
						Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / Camera.ViewportSize.Y)
					if Esp.Settings.Sleeping == true then
						v.Tracer.To = Vector2.new(x, (y - h) - v.Sleeping.TextBounds.Y * 0.5)
					else
						v.Tracer.To = Vector2.new(x, y - h * 0.5)
					end
				end
			else
				v.Tracer.Visible = false
			end
			if OnScreen == true and Esp.Settings.ViewAngle == true and Distance <= Esp.Settings.RenderDistance then
				if Esp.Settings.TeamCheck == true and TeamTag == false then
					v.ViewAngle.Visible = true
				elseif Esp.Settings.TeamCheck == true and TeamTag == true then
					v.ViewAngle.Visible = false
				else
					v.ViewAngle.Visible = true
				end
				if Esp.Settings.TargetSleepers == true and v.PlayerTable.sleeping == true then
					v.ViewAngle.Visible = false
				end
				v.ViewAngle.Color = Esp.Settings.ViewAngleColor
				v.ViewAngle.Thickness = Esp.Settings.ViewAngleThickness
				v.Transparency = Esp.Settings.ViewAngleTransparrency
				local headpos = Camera:WorldToViewportPoint(Character.Head.Position)
				local offsetCFrame = CFrame.new(0, 0, -4)
				v.ViewAngle.From = Vector2.new(headpos.X, headpos.Y)
				local value = math.clamp(1 / Distance * 100, 0.1, 1)
				local dir = Character.Head.CFrame:ToWorldSpace(offsetCFrame)
				offsetCFrame = offsetCFrame * CFrame.new(0, 0, 0.4)
				local dirpos = Camera:WorldToViewportPoint(Vector3.new(dir.X, dir.Y, dir.Z))
				if OnScreen == true then
					v.ViewAngle.To = Vector2.new(dirpos.X, dirpos.Y)
					offsetCFrame = CFrame.new(0, 0, -4)
				end
			else
				v.ViewAngle.Visible = false
			end
		else
			v.Box.Visible = false
			v.BoxOutline.Visible = false
			v.Tool.Visible = false
			v.Armour.Visible = false
			v.Sleeping.Visible = false
			v.ViewAngle.Visible = false
			v.Tracer.Visible = false
		end
	end
end
local SilentTabbox = Tabs.Combat:AddLeftTabbox()
local SilentTab = SilentTabbox:AddTab('silent aim')
local FovTab = SilentTabbox:AddTab('fov circle')

--* Silent Aim *--

SilentTab:AddToggle('SilentAim',{Text='enabled',Default=true}):AddKeyPicker('SilentKey', {Default='MB2',SyncToggleState=true,Mode='Hold',Text='Silent Aim',NoUI=false}):OnChanged(function(Value)
Combat.Settings.SilentEnabled = Value
end)
SilentTab:AddSlider('HitChance', {Text='hit chance:',Default=100,Min=0,Max=100,Rounding=0,Compact=false,Suffix="%"}):OnChanged(function(Value)
Combat.Settings.SilentHitChance = Value
end)
SilentTab:AddSlider('HitChance', {Text='distance:',Default=1000,Min=0,Max=2500,Rounding=0,Compact=false,Suffix=" studs"}):OnChanged(function(Value)
Combat.Settings.RenderDistance = Value
end)
SilentTab:AddToggle('HighlightTarget',{Text='highlight target',Default=false}):AddColorPicker('HighlightTargetColor',{Default=Color3.fromRGB(58, 0, 255),Title='Color'}):OnChanged(function(value)
Esp.Settings.HighlightTarget = value
end)
Options.HighlightTargetColor:OnChanged(function(ValueHighlight)
Esp.Settings.HighlightTargetColor = ValueHighlight
end)
SilentTab:AddToggle('Snapline',{Text='snaplines',Default=false}):AddColorPicker('SnaplineColor',{Default=Color3.fromRGB(58, 0, 255),Title='Color'})
SilentTab:AddToggle('Snapcircles',{Text='snapcircles',Default=false}):AddColorPicker('SnapcirclesColor',{Default=Color3.fromRGB(58, 0, 255),Title='Color'}):OnChanged(function(Value)
Fov.Settings.CircleLine = Value
CircleLine.Visible = Value
end)
Options.SnapcirclesColor:OnChanged(function(Value25)
Fov.Settings.CircleLineColor = Value25
CircleLine.Color = Value25
end)

SilentTab:AddDropdown('SnaplinePosition', {Values = {"Bottom","Middle","Top"},Default = 2,Multi = false,Text = 'position:'}):OnChanged(function(Value)
Fov.Settings.SnaplinePosition = Value
end)
SilentTab:AddToggle('SleeperCheck',{Text='sleeper check',Default=true}):OnChanged(function(Value)
Combat.Settings.SleeperCheck = Value
end)

SilentTab:AddDropdown('SilentHitpart', {Values = {"Head", "HumanoidRootPart", "Torso", "LowerTorso", "RightHand", "LeftHand", "RightFoot", "LeftFoot"}, Default = 1, Multi = false, Text = 'hitpart:'}):OnChanged(function(Value)
Combat.Settings.SilentAimPart = Value
end)

--* Fov Circle *--

FovTab:AddToggle('Fov',{Text='enabled',Default=false}):AddColorPicker('FovColor',{Default=Color3.fromRGB(58, 0, 255),Title='Color'})
FovTab:AddToggle('Dynamic',{Text='dynamic',Default=true})
FovTab:AddToggle('FovHighlight',{Text='highlight',Default=false}):AddColorPicker('FovHighlightColor',{Default=Color3.fromRGB(0, 178, 255),Title='Color'})
FovTab:AddToggle('Filled',{Text='filled',Default=false}):OnChanged(function(Value)
Fov.Settings.FovFilled = Value;FovCircle.Filled = Value
Fov.Settings.FovOutlineFilled = Value;FovCircleOutline.Filled = Value
end)
FovTab:AddSlider('FovSize', {Text='size:',Default=120,Min=5,Max=500,Rounding=0,Compact=false}):OnChanged(function(Value)
Fov.Settings.FovSize = Value;FovCircle.Radius = Value
Fov.Settings.FovOutlineSize = Value;FovCircleOutline.Radius = Value
end)
FovTab:AddSlider('Transparency', {Text='transparency:',Default=1,Min=0,Max=1,Rounding=2,Compact=false,Suffix="%"}):OnChanged(function(Value)
Fov.Settings.FovTransparency = Value;FovCircle.Transparency = Value
end)
FovTab:AddDropdown('FovPosition', {Values = {"To Screen","To Mouse"},Default = 1,Multi = false,Text = 'position:'}):OnChanged(function(Value)
Fov.Settings.FovPosition = Value
Fov.Settings.FovOutlinePosition = Value
end)

game:GetService("RunService").RenderStepped:Connect(function()

if Functions:GetClosest() ~= nil and Toggles.FovHighlight.Value == true then
  local p,t = Functions:GetClosest()
  FovCircle.Color = Fov.Settings.FovColor
  local Position,OnScreen = Camera:WorldToViewportPoint(Functions:GetClosest()[Combat.Settings.SilentAimPart]:GetPivot().p+Functions:Predict());
  if Fov.Settings.FovHighlight == true and Functions:GetClosest().Head.Teamtag.Enabled == false and OnScreen == true then
    FovCircle.Color = Fov.Settings.FovHighlightColor
  else
    FovCircle.Color=Color3.fromRGB(8, 0, 255)
  end
else
  FovCircle.Color = Fov.Settings.FovColor
end
if Functions:GetClosest() ~= nil and Toggles.Snapline.Value == true then
  local p,t = Functions:GetClosest()
  FovSnapline.Visible = true
  CircleLine.Visible = true
  local Position,OnScreen = Camera:WorldToViewportPoint(Functions:GetClosest()[Combat.Settings.SilentAimPart]:GetPivot().p+Functions:Predict());
  if Combat.Settings.TeamCheck == true and Functions:GetClosest().Head.Teamtag.Enabled == false and OnScreen == true then
    FovSnapline.To = Position
    CircleLine.Position = Position
  elseif OnScreen == true then
    FovSnapline.To = Position
    CircleLine.Position = Position
  end
else
  FovSnapline.Visible = false
  CircleLine.Visible = false
end
if Functions:GetClosest() ~= nil and Toggles.Snapcircles.Value == true then
  local p,t = Functions:GetClosest()
  CircleLine.Visible = true
  local Position,OnScreen = Camera:WorldToViewportPoint(Functions:GetClosest()[Combat.Settings.SilentAimPart]:GetPivot().p+Functions:Predict());
  if Combat.Settings.TeamCheck == true and Functions:GetClosest().Head.Teamtag.Enabled == false and OnScreen == true then
    CircleLine.Position = Position
  elseif OnScreen == true then
    CircleLine.Position = Position
  end
else
  CircleLine.Visible = false
end
Fov.Settings.RealFovSize=FovCircle.Radius
Fov.Settings.RealFovOutlineSize=FovCircle.Radius
if Fov.Settings.Dynamic == true then
  local set = Fov.Settings.FovSize * ((Fov.Settings.FovSize-Camera.FieldOfView)/70 + 0.14) + 17.5
  local set2 = Fov.Settings.FovOutlineSize * ((Fov.Settings.FovOutlineSize-Camera.FieldOfView)/70 + 0.14) + 17.5
  FovCircle.Radius = set
  FovCircleOutline.Radius = set
else
  FovCircle.Radius=Fov.Settings.FovSize
  FovCircleOutline.Radius=Fov.Settings.FovOutlineSize
end
if Fov.Settings.FovPosition == "To Screen" then
  FovCircle.Position = Vector2.new(Camera.ViewportSize.X/2,Camera.ViewportSize.Y/2)
  FovCircleOutline.Position = Vector2.new(Camera.ViewportSize.X/2,Camera.ViewportSize.Y/2)
else
  local MousePos = Camera.WorldToViewportPoint(Camera,game.Players.LocalPlayer:GetMouse().Hit.p)
  FovCircle.Position = Vector2.new(MousePos.X,MousePos.Y)
  FovCircleOutline.Position = Vector2.new(MousePos.X,MousePos.Y)
end
if Fov.Settings.SnaplinePosition == "Bottom" then
  FovSnapline.From=Vector2.new(Camera.ViewportSize.X/2,Camera.ViewportSize.Y)
elseif Fov.Settings.SnaplinePosition == "Middle" then
  FovSnapline.From=Vector2.new(Camera.ViewportSize.X/2,Camera.ViewportSize.Y/2)
elseif Fov.Settings.SnaplinePosition == "Top" then
  FovSnapline.From=Vector2.new(Camera.ViewportSize.X / 2, 0)
end
end)

--// Fov Switches
Toggles.Dynamic:OnChanged(function(Value)
Fov.Settings.Dynamic = Value
Fov.Settings.OutlineDynamic = Value
end)
Toggles.FovHighlight:OnChanged(function(Value)
Fov.Settings.FovHighlight = Value
end)
Options.FovHighlightColor:OnChanged(function(Value)
Fov.Settings.FovHighlightColor = Value
end)
Toggles.Fov:OnChanged(function(Value)
Fov.Settings.FovEnabled = Value
FovCircle.Visible = Value
Fov.Settings.FovOutlineEnabled = Value
FovCircleOutline.Visible = Value
end)
Options.FovColor:OnChanged(function(Value)
Fov.Settings.FovColor = Value
FovCircle.Color = Value
end)

--// Silent Aim Switches
Toggles.Snapline:OnChanged(function(Value)
Fov.Settings.Snapline = Value
FovSnapline.Visible = Value
end)
Options.SnaplineColor:OnChanged(function(Value)
Fov.Settings.SnaplineColor = Value
FovSnapline.Color=Value
end)

--// Silent Aim
local oldFunctionGun; oldFunctionGun = hookfunction(getupvalues(getrenv()._G.modules.FPS.ToolControllers.RangedWeapon.PlayerFire)[1],function(...)
args = {...}
local Player,PlayerTable = Functions:GetClosest()
if Combat.Settings.SilentEnabled == true and Player ~= nil and (CharcaterMiddle:GetPivot().Position-Player:GetPivot().Position).Magnitude <= Combat.Settings.RenderDistance and math.random(0,100) <= Combat.Settings.SilentHitChance then
if Combat.Settings.TeamCheck == true and Player.Head.Teamtag.Enabled == false then
if Combat.Settings.SleeperCheck == true and PlayerTable.sleeping == false then
args[1] = CFrame.lookAt(args[1].Position,Player[Combat.Settings.SilentAimPart]:GetPivot().p+Functions:Predict())
else
args[1] = CFrame.lookAt(args[1].Position,Player[Combat.Settings.SilentAimPart]:GetPivot().p+Functions:Predict())
end
else
if Combat.Settings.SleeperCheck == true and PlayerTable.sleeping == false then
args[1] = CFrame.lookAt(args[1].Position,Player[Combat.Settings.SilentAimPart]:GetPivot().p+Functions:Predict())
else
args[1] = CFrame.lookAt(args[1].Position,Player[Combat.Settings.SilentAimPart]:GetPivot().p+Functions:Predict())
end
end
end
return oldFunctionGun(unpack(args))
end)

local oldFunction; oldFunction = hookfunction(getupvalues(getrenv()._G.modules.FPS.ToolControllers.BowSpecial.PlayerFire)[4],function(...)
args = {...}
local Player,PlayerTable = Functions:GetClosest()
if Combat.Settings.SilentEnabled == true and Player ~= nil and (CharcaterMiddle:GetPivot().Position-Player:GetPivot().Position).Magnitude <= Combat.Settings.RenderDistance and math.random(0,100) <= Combat.Settings.SilentHitChance then
if Combat.Settings.TeamCheck == true and Player.Head.Teamtag.Enabled == false then
if Combat.Settings.SleeperCheck == true and PlayerTable.sleeping == false then
args[1] = CFrame.lookAt(args[1].Position,Player[Combat.Settings.SilentAimPart]:GetPivot().p+Functions:Predict())
else
args[1] = CFrame.lookAt(args[1].Position,Player[Combat.Settings.SilentAimPart]:GetPivot().p+Functions:Predict())
end
else
if Combat.Settings.SleeperCheck == true and PlayerTable.sleeping == false then
args[1] = CFrame.lookAt(args[1].Position,Player[Combat.Settings.SilentAimPart]:GetPivot().p+Functions:Predict())
else
args[1] = CFrame.lookAt(args[1].Position,Player[Combat.Settings.SilentAimPart]:GetPivot().p+Functions:Predict())
end
end
end
return oldFunction(unpack(args))
end)
--Connections
local PlayerUpdater = game:GetService("RunService").RenderStepped
local PlayerConnection = PlayerUpdater:Connect(function()
	Esp:UpdateEsp()
end)

--Init Functions

for i, v in pairs(getupvalues(getrenv()._G.modules.Player.GetPlayerModel)[1]) do
	if not table.find(cache, v) then
		table.insert(cache, v)
		Esp:CreateEsp(v)
	end
end

game:GetService("Workspace").ChildAdded:Connect(function(child)
	if child:FindFirstChild("HumanoidRootPart") then
		for i, v in pairs(getupvalues(getrenv()._G.modules.Player.GetPlayerModel)[1]) do
			if not table.find(cache, v) then
				Esp:CreateEsp(v)
				table.insert(cache, v)
			end
		end
	end
end)

local PlayerVisualTabbox = Tabs.Visuals:AddLeftTabbox()
local PlayerVisualTab = PlayerVisualTabbox:AddTab("Players")
local PlayerSettingsVisualTab = PlayerVisualTabbox:AddTab("Settings")
local PlayerVisualTabbox = Tabs.Visuals:AddRightTabbox()

PlayerVisualTab:AddToggle("Boxes", { Text = "Boxes", Default = false })
	:AddColorPicker("BoxesColor", { Default = Color3.fromRGB(44, 0, 221), Title = "Color" })
	:AddColorPicker("BoxesOutlineColor", { Default = Color3.fromRGB(0, 0, 0), Title = "Color" })
PlayerVisualTab:AddToggle("Sleeping", { Text = "Sleeping", Default = false })
	:AddColorPicker("SleepingColor", { Default = Color3.fromRGB(44, 0, 221), Title = "Color" })
PlayerVisualTab:AddToggle("Distances", { Text = "Distance", Default = false })
	:AddColorPicker("DistancesColor", { Default = Color3.fromRGB(44, 0, 221), Title = "Color" })
PlayerVisualTab:AddToggle("Armour", { Text = "Armour", Default = false })
	:AddColorPicker("ArmourColor", { Default = Color3.fromRGB(0, 255, 255), Title = "Color" })
PlayerVisualTab:AddToggle("Tool", { Text = "Tool", Default = false })
	:AddColorPicker("ToolColor", { Default = Color3.fromRGB(0, 255, 255), Title = "Color" })
PlayerVisualTab:AddToggle("ViewAngle", { Text = "View Angle", Default = false })
	:AddColorPicker("ViewAngleColor", { Default = Color3.fromRGB(44, 0, 221), Title = "Color" })
PlayerVisualTab:AddToggle("Tracer", { Text = "Tracer", Default = false })
	:AddColorPicker("TracerColor", { Default = Color3.fromRGB(44, 0, 221), Title = "Color" })

--Esp Switches
Toggles.ViewAngle:OnChanged(function(Value)
	Esp.Settings.ViewAngle = Value
end)
Options.ViewAngleColor:OnChanged(function(Value)
	Esp.Settings.ViewAngleColor = Value
end)
Toggles.Tracer:OnChanged(function(Value)
	Esp.Settings.Tracer = Value
end)
Options.TracerColor:OnChanged(function(Value)
	Esp.Settings.TracerColor = Value
end)
Toggles.Armour:OnChanged(function(Value)
	Esp.Settings.Armour = Value
end)
Options.ToolColor:OnChanged(function(Value)
	Esp.Settings.ToolColor = Value
end)
Toggles.Tool:OnChanged(function(Value)
	Esp.Settings.Tool = Value
end)
Options.ArmourColor:OnChanged(function(Value)
	Esp.Settings.ArmourColor = Value
end)
Toggles.Armour:OnChanged(function(Value)
	Esp.Settings.Armour = Value
end)
Toggles.Distances:OnChanged(function(Value)
	Esp.Settings.Distances = Value
end)
Options.DistancesColor:OnChanged(function(Value)
	Esp.Settings.DistanceColor = Value
end)
Options.SleepingColor:OnChanged(function(Value)
	Esp.Settings.SleepingColor = Value
end)
Toggles.Sleeping:OnChanged(function(Value)
	Esp.Settings.Sleeping = Value
end)
Options.BoxesColor:OnChanged(function(Value)
	Esp.Settings.BoxesColor = Value
end)
Options.BoxesOutlineColor:OnChanged(function(Value)
	Esp.Settings.BoxesOutlineColor = Value
end)
Toggles.Boxes:OnChanged(function(Value)
	Esp.Settings.Boxes = Value
end)
PlayerSettingsVisualTab:AddSlider(
	"RenderDistance",
	{ Text = "Render Distance", Default = 1500, Min = 1, Max = 1500, Rounding = 0, Compact = false, Suffix = "s" }
):OnChanged(function(Value)
	Esp.Settings.RenderDistance = Value
end)
PlayerSettingsVisualTab:AddToggle("TargetSleepers", { Text = "Dont Show Sleepers", Default = false })
	:OnChanged(function(Value)
		Esp.Settings.TargetSleepers = Value
	end)
PlayerSettingsVisualTab:AddToggle("BoxesOutlines", { Text = "Box Outlines", Default = false }):OnChanged(function(Value)
	Esp.Settings.BoxesOutline = Value
end)
PlayerSettingsVisualTab:AddToggle("TeamCheck", { Text = "Team Check", Default = false }):OnChanged(function(Value)
	Esp.Settings.TeamCheck = Value
end)
PlayerSettingsVisualTab:AddToggle("TextOutline", { Text = "Text Outlines", Default = false }):OnChanged(function(Value)
	Esp.Settings.TextOutline = Value
end)
PlayerSettingsVisualTab:AddDropdown(
	"TracerPosition",
	{ Values = { "Bottom", "Middle", "Top" }, Default = 1, Multi = false, Text = "Tracer Position" }
):OnChanged(function(Value)
	Esp.Settings.TracerFrom = Value
end)




local SkinChangerTabBox = Tabs.Visuals:AddRightTabbox('skinbox')
local SkinChangerTab = SkinChangerTabBox:AddTab('skinbox')

--* Skinbox *--

local SkinChoice = "Galaxy"
local SkinsEnabled = false

function CheckSkins()
local tbl = {}
for i, v in pairs(game:GetService("ReplicatedStorage").ItemSkins:GetChildren()) do
table.insert(tbl, v.Name)
end
return tbl
end
function SetCammo(SkinName)
if not require(game:GetService("ReplicatedStorage").ItemConfigs[getrenv()._G.modules.FPS.GetEquippedItem().id]).HandModel then
return
end
local GunName = require(game:GetService("ReplicatedStorage").ItemConfigs[getrenv()._G.modules.FPS.GetEquippedItem().id]).HandModel
if table.find(CheckSkins(), GunName) then
local SkinFolder = game:GetService("ReplicatedStorage").ItemSkins[GunName]
local AnimationModule = require(SkinFolder:FindFirstChild("AnimatedSkinPrefab"))
if SkinName == "Lightning" then
AnimationModule.ApplyToModel(workspace.Ignore.FPSArms.HandModel, "rbxassetid://6555500992", 1, 0.3)
elseif SkinName == "Galaxy" then
AnimationModule.ApplyToModel(workspace.Ignore.FPSArms.HandModel, "rbxassetid://9305457875", 1, 0.3)
elseif SkinName == "Swirl" then
AnimationModule.ApplyToModel(workspace.Ignore.FPSArms.HandModel, "rbxassetid://13199296652", 1, 0.3)
elseif SkinName == "Wavey" then
AnimationModule.ApplyToModel(workspace.Ignore.FPSArms.HandModel, "rbxassetid://13898657945", 1, 0.3)
elseif SkinName == "RedGalaxy" then
AnimationModule.ApplyToModel(workspace.Ignore.FPSArms.HandModel, "rbxassetid://1619172543", 1, 0.3)
elseif SkinName == "Marble" then
AnimationModule.ApplyToModel(workspace.Ignore.FPSArms.HandModel, "rbxassetid://8904067198", 1, 0.01)
elseif SkinName == "Lava" then
AnimationModule.ApplyToModel(workspace.Ignore.FPSArms.HandModel, "rbxassetid://7077560268", 1, 0.3)
elseif SkinName == "Blackout" then
AnimationModule.ApplyToModel(workspace.Ignore.FPSArms.HandModel, "rbxassetid://5847588525", 1, 0.3)
elseif SkinName == "Snake" then
AnimationModule.ApplyToModel(workspace.Ignore.FPSArms.HandModel, "rbxassetid://7457460026", 1, 0.3)
elseif SkinName == "Banana" then
AnimationModule.ApplyToModel(workspace.Ignore.FPSArms.HandModel, "rbxassetid://338693178", 2, 0.3)
elseif SkinName == "Death" then
AnimationModule.ApplyToModel(workspace.Ignore.FPSArms.HandModel, "rbxassetid://11896030190", 1, 0.3)
end
end
end
game:GetService("Workspace").Ignore.FPSArms.ChildAdded:Connect(function()
if game:GetService("Workspace").Ignore.FPSArms:WaitForChild("HandModel") and SkinsEnabled == true then
SetCammo(SkinChoice)
end
end)

SkinChangerTab:AddToggle('SkinsEnabled', {Text = 'enabled', Default = false}):OnChanged(function(value)
SkinsEnabled = value
end)
SkinChangerTab:AddDropdown('SkinChoice', {Values = {"Lightning", "Galaxy", "Swirl", "Wavey", "RedGalaxy", "Marble", "Lava", "Blackout", "Snake", "Banana", "Death"}, Default = 1, Multi = false, Text = 'custom skins:'}):OnChanged(function(value)
SkinChoice = value
end)


local FieldOfViewTabBox = Tabs.Visuals:AddRightTabbox('field of view')
local FieldOfViewTab = FieldOfViewTabBox:AddTab('field of view')

--* Field Of View *--

local FieldOfViewEnabled = false
local FieldOfViewValue = 70
local CurrentSliderValue3 = 70
game:GetService("RunService").RenderStepped:Connect(function()
local fovFunc = nil
for i,v in pairs(getreg()) do
if type(v) == "function" and getfenv(v).script.Name == "Camera" and #getupvalues(v) >= 18 then
  fovFunc = v
end
end
setupvalue(fovFunc,18,FieldOfViewValue)
end)

FieldOfViewTab:AddToggle('FieldOfView', { Text = 'enabled', Default = false }):AddKeyPicker('fieldofviewkey', { Default = 'Non', SyncToggleState = true, Mode = 'Toggle', Text = 'field of view', NoUI = true }):OnChanged(function(value)
FieldOfViewEnabled = value
if not FieldOfViewEnabled then
FieldOfViewValue = 70
else
FieldOfViewValue = CurrentSliderValue3
end
end)

FieldOfViewTab:AddSlider('FieldOfViewSlider', { Text = 'field of view:', Suffix = "Non", Default = 70, Min = 30, Max = 120, Rounding = 0, Compact = false }):OnChanged(function(sliderValue)
CurrentSliderValue3 = sliderValue
if FieldOfViewEnabled then
FieldOfViewValue = sliderValue
end
end)


local TrashTalkTabBox = Tabs.Misc:AddRightTabbox('trash talk')
local TrashTalkTab = TrashTalkTabBox:AddTab('trash talk')

--* Trash Talk *--

local Trashtalk = true
local Chats = {
["🌚ASTRO.CC🌚"] = {"stop being weird and get 🌚ASTRO.CC🌚"};
}

local _Network = getrenv()._G.modules.Network
local _SendCodes = getrenv()._G.modules.Network.SendCodes
game:GetService("LogService").MessageOut:Connect(function(message)
local extractedName = message:match("->([%w_]+)")
local initialHealth, finalHealth = message:match("(%-?%d+%.?%d*)%D*->(%-?%d+%.?%d*)hp")
local studsValue = message:match("(%d+%.?%d*)s")
if Trashtalk and extractedName and initialHealth and finalHealth and studsValue and extractedName ~= game.Players.LocalPlayer.Name then
if Trashtalk and tonumber(finalHealth) <= 0 then
  _Network.Send(_SendCodes.SEND_CHAT_MESSAGE, extractedName .. " killed from " .. studsValue .. "m, " .. Chats["🌚ASTRO.CC🌚"][math.random(1, #Chats["🌚ASTRO.CC🌚"])] .. " [.gg/🌚ASTRO.CC🌚]", "Global")
end
end
end)

local enabledspamchat = false
local chatSpammerText = ""
local WaitTime = 3
local function spamChat()
local args = {[1] = 27, [2] = chatSpammerText, [3] = "Global"}
while enabledspamchat do
  game:GetService("Players").LocalPlayer.RemoteEvent:FireServer(unpack(args))
  wait(WaitTime)
end
end

TrashTalkTab:AddToggle('Enabled_Toggle1', {Text = 'enabled', Default = false}):OnChanged(function(value)
Trashtalk = value
enabledspamchat = value
end)

TrashTalkTab:AddDropdown('', {Values = { 'None','Trash Talk', 'Chat Spammer' }, Default = 1, Multi = false, Text = 'type:'}):OnChanged(function(bool2)
if bool2 == "None" then
Trashtalk = true
enabledspamchat = false
elseif bool2 == "Trash Talk" then
Trashtalk = false
elseif bool2 == "Chat Spammer" then
spamChat()
end
end)

TrashTalkTab:AddSlider('SpamChatSpeed', {Text = 'speed:',Suffix = "s", Default = 3, Min = 1, Max = 10, Rounding = 0, Compact = false,}):OnChanged(function(SpamChatSpeedValue)
WaitTime = SpamChatSpeedValue
end)

TrashTalkTab:AddInput('ChatSpammer', {Default = "If you cant beat them join them [.gg/🌚ASTRO.CC🌚] on top!", Numeric = false, Finished = true, Text = 'chat spammer:', Placeholder = "Chat Spam Custom Text [HERE]"}):OnChanged(function(value)
chatSpammerText = value
end)

local CustomSkyTabBox = Tabs.Visuals:AddLeftTabbox('lighting')
local CustomSkyTab = CustomSkyTabBox:AddTab('lighting')

--* Lighting *--

local LightingEnabled = nil

CustomSkyTab:AddToggle('AWASZnfh', {Text = "enabled",Default = false,Tooltip = "Enables SkyTab",}):OnChanged(function(EnabledLighting)
LightingEnabled = EnabledLighting
end)

CustomSkyTab:AddToggle('z1AWASZnfh', {Text = "remove shadows",Default = false,Tooltip = "Global Shadows On/Off",}):OnChanged(function(GlobalShadowsToggle)
if LightingEnabled and GlobalShadowsToggle == true then
sethiddenproperty(game:GetService("Lighting"), "GlobalShadows", false)
elseif LightingEnabled and GlobalShadowsToggle == false then
sethiddenproperty(game:GetService("Lighting"), "GlobalShadows", true)
end
end)

CustomSkyTab:AddToggle('51z1AWASZnfh', {Text = "remove fog",Default = false,Tooltip = "Fog On/Off",}):OnChanged(function(RemoveFogToggle)
if LightingEnabled and RemoveFogToggle == true then
sethiddenproperty(game:GetService("Lighting"), "FogStart", math.huge)
elseif LightingEnabled and RemoveFogToggle == false then
sethiddenproperty(game:GetService("Lighting"), "FogStart", 150)
end
end)

CustomSkyTab:AddToggle('5za1z1AWASZnfh', {Text = "remove clouds",Default = false,Tooltip = "Clouds On/Off",}):OnChanged(function(RemoveCloudsToggle)
if LightingEnabled and RemoveCloudsToggle == true then
sethiddenproperty(game:GetService("Workspace").Terrain.Clouds, "Enabled", false)
elseif LightingEnabled and RemoveCloudsToggle == false then
sethiddenproperty(game:GetService("Workspace").Terrain.Clouds, "Enabled", true)
end
end)

CustomSkyTab:AddToggle('Grass', {Text = 'remove grass',Default = false,Tooltip = "Grass On/Off",}):OnChanged(function(GrassRemove)
if LightingEnabled and GrassRemove == true then
sethiddenproperty(game.Workspace.Terrain, "Decoration", false)
elseif LightingEnabled and GrassRemove == false then
sethiddenproperty(game.Workspace.Terrain, "Decoration", true)
end
end)

local GCEN = Color3.fromRGB(95, 100, 49)
local GRCEND = false

CustomSkyTab:AddToggle('CLRG', {Text = 'grass color', Default = true, Tooltip = "Off/On"}):AddColorPicker('ColorGrass', {Default = GCEN, Title = 'Changer Color Grass'})
Toggles.CLRG:OnChanged(function(T)
GRCEND = T
game:GetService("Workspace").Terrain:SetMaterialColor(Enum.Material.Grass, T and GCEN or Color3.fromRGB(95, 100, 49))
end)
Options.ColorGrass:OnChanged(function(Grass1)
if GRCEND then
GCEN = Grass1
game:GetService("Workspace").Terrain:SetMaterialColor(Enum.Material.Grass, Grass1)
end
end)

local CloudsColor = Color3.fromRGB(255, 255, 255)
local EnableCustomColor = false

CustomSkyTab:AddToggle('CLRG1', {Text = 'clouds color', Default = EnableCustomColor, Tooltip = "Off/On"}):AddColorPicker('ColorGrass1', {Default = CloudsColor, Title = 'Change Clouds Color'})
Toggles.CLRG1:OnChanged(function(T)
EnableCustomColor = T
game:GetService("Workspace").Terrain.Clouds.Color = T and CloudsColor or Color3.fromRGB(255, 255, 255)
end)
Options.ColorGrass1:OnChanged(function(NewColor)
if LightingEnabled and EnableCustomColor then
CloudsColor = NewColor
game:GetService("Workspace").Terrain.Clouds.Color = NewColor
end
end)

local Lighting = game:GetService("Lighting")
local ColorCorrection = Lighting:FindFirstChild("ColorCorrection")
if not ColorCorrection then
ColorCorrection = Instance.new("ColorCorrectionEffect")
ColorCorrection.Name = "ColorCorrection"
ColorCorrection.Parent = Lighting
end

CustomSkyTab:AddToggle('CLRG1', {Text = 'ambient', Default = EnableCustomColor, Tooltip = "Off/On"}):AddColorPicker('ColorAmbient1', {Default = Color3.fromRGB(255, 255, 255), Title = 'Change Ambient Color'})
Options.ColorAmbient1:OnChanged(function(NewColor2)
sethiddenproperty(ColorCorrection, "TintColor", NewColor2)
end)

CustomSkyTab:AddSlider('Exposure_sUS', {Text = 'exposure', Suffix = "%", Default = 0, Min = -5, Max = 5, Rounding = 1, Compact = true}):OnChanged(function(ExposureValue)
if LightingEnabled and sethiddenproperty(game:GetService("Lighting"), "ExposureCompensation", ExposureValue) then
end
end)

CustomSkyTab:AddSlider('Saturation_sUS', {Text = 'saturation',Suffix = "%",Default = 0,Min = -5,Max = 5,Rounding = 1,Compact = true}):OnChanged(function(SaturationValue)
if sethiddenproperty(ColorCorrection, "Saturation", SaturationValue) then
end
end)

CustomSkyTab:AddDropdown('World_Technology', {Values = { 'Technology', 'ShadowMap', 'Voxel', 'Compatibility' },Default = 1,Multi = false,Text = 'technology:',Tooltip = 'Game Technology',}):OnChanged(function(GPHZ)
if LightingEnabled and GPHZ == "Technology" then
sethiddenproperty(game.Lighting, "Technology", Enum.Technology.Future)
elseif LightingEnabled and GPHZ == "ShadowMap" then
sethiddenproperty(game.Lighting, "Technology", Enum.Technology.ShadowMap)
elseif LightingEnabled and GPHZ == "Voxel" then
sethiddenproperty(game.Lighting, "Technology", Enum.Technology.Voxel)
elseif LightingEnabled and GPHZ == "Compatibility" then
sethiddenproperty(game.Lighting, "Technology", Enum.Technology.Compatibility)
end
end)

local Sky = Instance.new("Sky",game:GetService("Lighting"))
CustomSkyTab:AddDropdown('World_Skybox', {Values = { 'Default', 'Neptune', 'Among Us', 'Nebula', 'Vaporwave', 'Clouds', 'Twilight', 'DaBaby', 'Minecraft', 'Chill', 'Redshift', 'Blue Stars', 'Blue Aurora' },Default = 1,Multi = false,Text = 'custom skybox:',Tooltip = 'Sky Changer',}):OnChanged(function(World_Skybox)
if LightingEnabled and lighting:FindFirstChild("Sky") then
lighting.Sky.SkyboxBk = skybox_assets[World_Skybox].SkyboxBk
lighting.Sky.SkyboxDn = skybox_assets[World_Skybox].SkyboxDn
lighting.Sky.SkyboxFt = skybox_assets[World_Skybox].SkyboxFt
lighting.Sky.SkyboxLf = skybox_assets[World_Skybox].SkyboxLf
lighting.Sky.SkyboxRt = skybox_assets[World_Skybox].SkyboxRt
lighting.Sky.SkyboxUp = skybox_assets[World_Skybox].SkyboxUp
end
end)



--// LOCAL \\--
local RightGroupBox = Tabs.Credits:AddRightGroupbox('MADE BY')
RightGroupBox:AddLabel('👑ASTRO👑')


local RightGroupBox = Tabs.Credits:AddLeftGroupbox('CREDIT')
RightGroupBox:AddLabel('👑ELION👑')

local RightGroupBox = Tabs.Credits:AddLeftGroupbox('BEST SCRIPTER')
RightGroupBox:AddLabel('👑ASTRO👑')




local RightGroupBox = Tabs.Credits:AddRightGroupbox('ASTRO DISCORD')
RightGroupBox:AddLabel('https://discord.gg/Cd6mQpHsBA')

--// MISC \\--
local RightGroupBox = Tabs.Misc:AddRightGroupbox('FREE CAM')
RightGroupBox:AddLabel('B = FREE CAM')
loadstring(game:HttpGet("https://pastebin.com/raw/9x5YxWXV", true))();


local TabBox = Tabs.Combat:AddRightTabbox()
local MiscTab = TabBox:AddTab('MODS')






MiscTab:AddToggle('', {Text = "Jump Crouch",Default = false,}):AddKeyPicker('JumpCrouchKey', {Default='Non',SyncToggleState=true,Mode='Toggle',Text='Jump Crouch',NoUI=false})
local stoprun = false
task.spawn(function()
while true do
  local state = Options.JumpCrouchKey:GetState()
  if state then
    keypress(0x57)
    keypress(0x10)
    wait(0.05)
    keypress(0x43)
    keypress(0x20)
    keyrelease(0x20)
    wait(0.5)
    keyrelease(0x43)
    wait(1)
  end
  if Library.Unloaded then break end
  wait()
end
end)
task.spawn(function()
while task.wait() do
  local state = Options.JumpCrouchKey:GetState()
  if not state then
    if stoprun then
      keyrelease(0x57)
      keyrelease(0x10)
      stoprun = false
    end
  else
    stoprun = true
  end
end
end)

MiscTab:AddToggle('LootAll',{Text='Loot All',Default=false}):AddKeyPicker('LootAllKey', {Default='Non',SyncToggleState=true,Mode='Toggle',Text='Loot All',NoUI=false})

Toggles.LootAll:OnChanged(function()
  for i = 1, 20 do
      game:GetService("Players").LocalPlayer.RemoteEvent:FireServer(12, i, true)
  end
end)

local XRAY22 = false
MiscTab:AddToggle('XRAY', {Text = 'XRAY', Default = false}):AddKeyPicker('XRAYKey', {Default='Non',SyncToggleState=true,Mode='Toggle',Text='XRAY',NoUI=false}):OnChanged(function()
    XRAY22 = Toggles.XRAY.Value
    if XRAY22 then
        for i,v in pairs(game:GetDescendants()) do
            if v:FindFirstChild("Hitbox") then
                v.Hitbox.Transparency = 0.6
            end
        end
    else
        for i,v in pairs(game:GetDescendants()) do
            if v:FindFirstChild("Hitbox") then
                v.Hitbox.Transparency = 0
            end
        end
    end
end)
MiscTab:AddLabel('deposit all'):AddKeyPicker('gazkb', { Default = 'Non', SyncToggleState = false, Mode = 'Toggle', Text = 'deposit all', NoUI = true })
Options.gazkb:OnClick(function()
for i = 1, 20 do
wait(0.03)
local ohNumber1 = 12
local ohNumber2 = i
local ohBoolean3 = false
game:GetService("Players").LocalPlayer.RemoteEvent:FireServer(ohNumber1, ohNumber2, ohBoolean3)
end
end)


local NoSlowDown = false
local old = getrenv()._G.modules.Character.SetSprintBlocked
ExploitsTab:AddToggle('NOSLOWDOWN',{Text='no slowdown',Default=false}):OnChanged(function(Value)
NoSlowDown = Value
getrenv()._G.modules.Character.SetSprintBlocked = function(...)
local args = {...}
if NoSlowDown then
  args[1] = false
  return old(unpack(args))
end
return old(...)
end
end)

local Misc = {
Settings = {
  JumpShoot = false,
  NoADS = false,
}
}

ExploitsTab:AddToggle('JumpShoot',{Text='jump shoot',Default=false}):OnChanged(function(Value)
Misc.Settings.JumpShoot = Value
end)
local oldIsGrounded;oldIsGrounded = hookfunction(getrenv()._G.modules.Character.IsGrounded,function(...)
if Misc.Settings.JumpShoot == true then
return true
else
return oldIsGrounded(...)
end
end)

ExploitsTab:AddToggle('NoADS',{Text='no ads',Default=false}):OnChanged(function(Value)
Misc.Settings.NoADS = Value
end)
local oldNoADS;oldNoADS = hookfunction(getrenv()._G.modules.Camera.SetVMAimingOffset,function(...)
if Misc.Settings.NoADS == true then
return true
else
return oldNoADS(...)
end
end)

local NoSway = false
ExploitsTab:AddToggle('NoSway',{Text='no sway',Default=false}):OnChanged(function(Value)
NoSway = Value
end)
local NoSwayHook;NoSwayHook = hookfunction(getrenv()._G.modules.Camera.SetSwaySpeed,function(...)
local args = {...}
if NoSway == true then
args[1] = 0
return NoSwayHook(unpack(args))
end
return NoSwayHook(...)
end)

ExploitsTab:AddToggle('NoReloadAnimation',{Text='no reload animation',Default=false}):OnChanged(function(Value)
gunMods.noReloadanimTog = Value
end)
local reloadDuringShoot;reloadDuringShoot = hookfunction(getupvalues(getrenv()._G.modules.FPS.ToolControllers.RangedWeapon.PlayerFire)[1],function(...)
local arg = {...}
if gunMods.noReloadanimTog == true then
arg[2]['ReloadTime'] = 0
return reloadDuringShoot(unpack(arg))
end
return reloadDuringShoot(...)
end)

ExploitsTab:AddToggle('ArrowGun', {Text = 'arrow gun',Default = false}):OnChanged(function(ArrowValue)
for I, V in pairs(getgc(true)) do
if type(V) == "table" and rawget(V, "TracerPart") then
  if ArrowValue == true then
    V.TracerPart = "Arrow"
  elseif ArrowValue == false then
    V.TracerPart = "Bullet"
  end
end
end
end)


local deleteWallsEnabled = false
ExploitsTab:AddToggle('', {Text = "delete walls",Default = false,Tooltip = "Left Click / Mouse Button 2 (MB2)",}):AddKeyPicker('', {Default='MB2',SyncToggleState=true,Mode='Toggle',Text='Delete Walls',NoUI=true}):OnChanged(function(value)
deleteWallsEnabled = value
end)

local Mouse = game.Players.LocalPlayer:GetMouse()
Mouse.Button1Down:connect(function()
if deleteWallsEnabled then
if not Mouse.Target then
  return
end
local targetName = Mouse.Target.Name
local allowedNames = {"Hitbox", "LeftWall", "RightWall", "LeftHinge", "Prim", "RightHinge"}
for _, name in ipairs(allowedNames) do
  if targetName == name then
    Mouse.Target:Destroy()
    break
  end
end
end
end)



local SpinbotTabBox = Tabs.Combat:AddRightTabbox('spinbot')
local SpinbotTab = SpinbotTabBox:AddTab('spinbot')

--* Spinbot *--

local fakeduck = false
local Spinbot = false
local SpinbotSpeed = 3
local SpinbotType = "Normal"
local value = 1
local SpinBotLM = false
local SpinBotV = false
SpinbotTab:AddToggle('Spinbot',{Text='enabled',Default=false}):OnChanged(function(Value)
Spinbot = Value
end)

SpinbotTab:AddSlider('SpinbotSpeed', {Text='speed:',Default=3,Min=1,Max=3,Rounding=0,Compact=false,Thickness = 3}):OnChanged(function(Value)
SpinbotSpeed = Value
end)

SpinbotTab:AddDropdown('SpinbotType', {Values = {"Normal", "Desync", "Random"},Default = 1,Multi = false,Text = 'type:'}):OnChanged(function(Value)
SpinbotType = Value
end)

local OldSpinHook
OldSpinHook = hookfunction(game.Players.LocalPlayer:FindFirstChild("RemoteEvent").FireServer, function(self, ...)
local args = {...}
if args[1] and args[2] and args[1] == 1 and typeof(args[2]) == "Vector3" and args[4] and Spinbot == true then
  if SpinBotLM == true and SpinbotType == "Desync" then
    args[4] = value
    value = value + SpinbotSpeed
  elseif SpinbotType == "Normal" or SpinBotLM == false then
    args[4] = value
    value = value - SpinbotSpeed
  end
end
if args[1] and args[2] and args[1] == 1 and typeof(args[2]) == "Vector3" and args[4] and Spinbot == true then
  if SpinBotV == true and SpinbotType == "Desync" then
    args[3] = 1.5000001192092896
  elseif SpinbotType == "Normal" or SpinBotV == false then
    args[3] = -1.5000001192092896
  elseif SpinbotType == "Random" or SpinBotV == false then
    args[3] = -1.5000001192092896
  end
end
return OldSpinHook(self, unpack(args))
end)
task.spawn(function()
while task.wait() do
  if SpinbotType == "Desync" then
    SpinBotV = not SpinBotV
  end
end
end)
task.spawn(function()
while task.wait(0.1) do
  if SpinbotType == "Desync" or SpinbotType == "Random" then
    SpinBotLM = not SpinBotLM
  end
end
end)

SpinbotTab:AddToggle('FakeCrouch', {Text = 'fake duck',Default = false,Tooltip = 'Makes u crouch for other people also they cant hear your footsteps'})
local OldCrouchHook; OldCrouchHook = hookfunction(game:GetService("Players").LocalPlayer:FindFirstChild("RemoteEvent").FireServer, function(self, ...)
local args = {...}
if args[1] == 2 and fakeduck == true then
  args[2] = true
end
return OldCrouchHook(self, unpack(args))
end)
Toggles.FakeCrouch:OnChanged(function() fakeduck = Toggles.FakeCrouch.Value end)
local function onFakeLagToggled(value)
  local networkClient = game:GetService("NetworkClient")
  networkClient:SetOutgoingKBPSLimit(value and 1 or 100)
end
SpinbotTab:AddToggle('FakeLag', {Text = 'fake lag', Default = false}):OnChanged(onFakeLagToggled)











--// CREDITS \\--




Library:SetWatermarkVisibility(true)

local FrameTimer = tick()
local FrameCounter = 0;
local FPS = 60;

local WatermarkConnection = game:GetService('RunService').RenderStepped:Connect(function()
    FrameCounter += 1;

    if (tick() - FrameTimer) >= 1 then
        FPS = FrameCounter;
        FrameTimer = tick();
        FrameCounter = 0;
    end;

    Library:SetWatermark(("🌚ASTRO.CC🌚 | Build: PAID | Game: Trident Survival"):format(
        math.floor(FPS),
        math.floor(game:GetService('Stats').Network.ServerStatsItem['Data Ping']:GetValue())
    ));
end);

Library.KeybindFrame.Visible = true;

Library:OnUnload(function()
    WatermarkConnection:Disconnect()

    print('Unloaded!')
    Library.Unloaded = true
end)

local MenuGroup = Tabs['UI Settings']:AddRightGroupbox('Menu')

MenuGroup:AddButton('Unload', function() Library:Unload() end)
MenuGroup:AddButton("Rejoin Server", function()
    Library:Notify("Rejoining", 30)
    wait(1)
    local ts = game:GetService("TeleportService")
    local p = game:GetService("Players").LocalPlayer
    ts:Teleport(game.PlaceId, p)
end)
MenuGroup:AddLabel('Menu bind'):AddKeyPicker('MenuKeybind', { Default = 'K', NoUI = true, Text = 'Menu keybind' })
MenuGroup:AddDivider()
local playerCountLabel = MenuGroup:AddLabel("Player Count: 0", nil, true)
local function updatePlayerCount()
local playerCount = #game:GetService("Players"):GetPlayers()
playerCountLabel:SetText("Players Online : " .. playerCount)
end
game:GetService("Players").PlayerAdded:Connect(updatePlayerCount)
game:GetService("Players").PlayerRemoving:Connect(updatePlayerCount)
updatePlayerCount()
MenuGroup:AddDivider()
MenuGroup:AddLabel('Credits', true)
MenuGroup:AddLabel('Made by 🌚ASTRO🌚', true)
Library.ToggleKeybind = Options.MenuKeybind

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)

SaveManager:IgnoreThemeSettings()

SaveManager:SetIgnoreIndexes({ 'MenuKeybind' })

ThemeManager:SetFolder('🌚ASTRO.CC🌚')
SaveManager:SetFolder('🌚ASTRO.CC🌚/TRIDENT SURVIVAL')

SaveManager:BuildConfigSection(Tabs['UI Settings'])

ThemeManager:ApplyToTab(Tabs['UI Settings'])

SaveManager:LoadAutoloadConfig()
wait(0)Library:Notify("Thanks for using 🌚ASTRO.CC🌚")
wait(0)Library:Notify("Status : 🟢Undetected")
