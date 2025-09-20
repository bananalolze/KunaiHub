-- Kunai Hub for Murder Mystery 2
-- Uses Rayfield UI with fallback for Android compatibility
-- Use at your own risk! May result in a ban.

-- Load Rayfield Library
local success, Rayfield = pcall(function()
    return loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
end)
if not success then
    game.StarterGui:SetCore("SendNotification", {
        Title = "Error",
        Text = "Rayfield failed to load. Using fallback mode. Check executor or internet. Script continues.",
        Duration = 10,
        Color = Color3.fromRGB(255, 0, 0)
    })
    Rayfield = {CreateWindow = function() return {CreateTab = function() return {CreateToggle = function() end, CreateButton = function() end} end, Notify = function() end, Destroy = function() end} end}
end

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

-- Variables
local autoShootMurder = false
local killEveryone = false
local autoEspPlayers = false

-- Role Detection
local function getPlayerRole(player)
    local character = player.Character
    if not character then return "Unknown" end
    
    local gameData = ReplicatedStorage:FindFirstChild("GameData") or ReplicatedStorage:FindFirstChild("MurderData")
    if gameData then
        local roles = gameData:FindFirstChild("Roles")
        if roles and roles:FindFirstChild(player.Name) then
            local roleValue = roles[player.Name].Value
            if roleValue == "Sheriff" then return "Sheriff"
            elseif roleValue == "Murderer" then return "Murderer"
            else return "Innocent" end
        end
    end
    
    local tool = character:FindFirstChildOfClass("Tool")
    if tool and tool.Name == "Gun" then return "Sheriff" end
    if character:FindFirstChild("Knife") then return "Murderer" end
    return "Innocent"
end

-- Predicted Role (Refined)
local lastMove = {}
local function predictRole(player)
    local character = player.Character
    if not character or not HumanoidRootPart then return false end
    local distance = (HumanoidRootPart.Position - character.HumanoidRootPart.Position).Magnitude
    local role = getPlayerRole(player)
    local humanoid = character:FindFirstChild("Humanoid")
    if humanoid and humanoid.Health > 0 and distance < 12 and role == "Innocent" then
        lastMove[player.Name] = lastMove[player.Name] or tick()
        if tick() - lastMove[player.Name] > 5 and not (character:FindFirstChildOfClass("Tool") or character:FindFirstChild("Knife")) then
            return true
        elseif humanoid.MoveDirection.Magnitude > 0 then
            lastMove[player.Name] = tick()
        end
    end
    return false
end

-- Distance Calculation
local function getDistanceFromCharacter(targetRoot)
    if not HumanoidRootPart or not targetRoot then return 0 end
    return math.floor((HumanoidRootPart.Position - targetRoot.Position).Magnitude)
end

-- Create Window
local Window = Rayfield:CreateWindow({
    Name = "Kunai Hub v1.5",
    LoadingTitle = "Kunai Hub Initializing...",
    LoadingSubtitle = "by BananaLolze",
    ConfigurationSaving = {Enabled = true, FolderName = "KunaiHubConfig", FileName = "MM2Settings"},
    Discord = {Enabled = false, Invite = "noinvitelinkyet", RememberJoins = true},
    KeySystem = false
})

-- Apply Custom Theme
if Window.SetTheme then
    Window:SetTheme({
        Accent = Color3.fromRGB(150, 0, 150),
        LightContrast = Color3.fromRGB(40, 40, 40),
        DarkContrast = Color3.fromRGB(30, 30, 30),
        TextColor = Color3.fromRGB(255, 255, 255)
    })
end

-- Notify Load
if Window.Notify then
    Window:Notify({Title = "Kunai Hub Loaded", Content = "Ready for MM2!", Duration = 5, Image = 4483362458})
else
    game.StarterGui:SetCore("SendNotification", {Title = "Kunai Hub", Text = "Loaded! Use tabs to activate.", Duration = 5})
end

-- Tab Creation
local function createTab(name)
    local tab = Window:CreateTab(name)
    if not tab then
        game.StarterGui:SetCore("SendNotification", {
            Title = "Debug",
            Text = name .. " tab failed to create. Report your executor!",
            Duration = 10,
            Color = Color3.fromRGB(255, 165, 0)
        })
        return {CreateToggle = function() end, CreateButton = function() end}
    end
    return tab
end

-- Main Tab
local MainTab = createTab("Main")
if MainTab then
    MainTab:CreateButton({
        Name = "Auto Shoot Murder >",
        Callback = function()
            autoShootMurder = not autoShootMurder
            local role = getPlayerRole(LocalPlayer)
            if autoShootMurder and role ~= "Sheriff" then
                autoShootMurder = false
                if Window.Notify then Window:Notify({Title = "Error", Content = "You are not Sheriff/You don't have Gun", Duration = 5}) end
            else
                if Window.Notify then Window:Notify({Title = "Auto Shoot", Content = "Auto Shoot " .. (autoShootMurder and "Enabled" or "Disabled"), Duration = 3}) end
            end
        end
    })
    MainTab:CreateButton({
        Name = "Auto Kill Everyone >",
        Callback = function()
            killEveryone = not killEveryone
            local role = getPlayerRole(LocalPlayer)
            if killEveryone and role ~= "Murderer" then
                killEveryone = false
                if Window.Notify then Window:Notify({Title = "Error", Content = "You are not Murderer", Duration = 5}) end
            else
                if Window.Notify then Window:Notify({Title = "Kill Everyone", Content = "Kill Everyone " .. (killEveryone and "Enabled" or "Disabled"), Duration = 3}) end
            end
        end
    })
end

-- ESP Tab
local ESPTab = createTab("ESP")
if ESPTab then
    ESPTab:CreateToggle({
        Name = "Auto ESP Player Roles",
        CurrentValue = false,
        Flag = "AutoESPToggle",
        Callback = function(Value)
            autoEspPlayers = Value
            if Window.Notify then Window:Notify({Title = "Auto ESP", Content = "Auto ESP " .. (Value and "Enabled" or "Disabled"), Duration = 3}) end
            if not Value then
                for _, player in pairs(Players:GetPlayers()) do
                    if player ~= LocalPlayer and player.Character then
                        local billboardGui = player.Character:FindFirstChild("HumanoidRootPart") and player.Character.HumanoidRootPart:FindFirstChild("RoleESPBillboard")
                        if billboardGui then billboardGui:Destroy() end
                    end
                end
            end
        end
    })
end

-- Settings Tab
local SettingsTab = createTab("Settings")
if SettingsTab then
    SettingsTab:CreateButton({
        Name = "Close Hub",
        Callback = function()
            if Window.Destroy then Window:Destroy() end
            if Window.Notify then Window:Notify({Title = "Kunai Hub", Content = "Closed. Goodbye!", Duration = 3}) end
        end
    })
end

-- Functionality
RunService.RenderStepped:Connect(function()
    -- Auto Shoot Murder (Sheriff only)
    if autoShootMurder and getPlayerRole(LocalPlayer) == "Sheriff" then
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character and getPlayerRole(player) == "Murderer" then
                local targetRoot = player.Character:FindFirstChild("HumanoidRootPart")
                if targetRoot and HumanoidRootPart then
                    HumanoidRootPart.CFrame = CFrame.new(targetRoot.Position) * CFrame.Angles(0, 0, 0)
                    local gun = Character:FindFirstChild("Gun")
                    if gun and gun:FindFirstChild("Handle") then
                        local humanoid = player.Character:FindFirstChild("Humanoid")
                        if humanoid and humanoid.Health > 0 then
                            humanoid.Health = 0 -- Simplified kill
                        end
                    end
                end
            end
        end
    end

    -- Kill Everyone (Murderer only)
    if killEveryone and getPlayerRole(LocalPlayer) == "Murderer" then
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                local targetRoot = player.Character:FindFirstChild("HumanoidRootPart")
                local humanoid = player.Character:FindFirstChild("Humanoid")
                if targetRoot and humanoid and humanoid.Health > 0 then
                    HumanoidRootPart.CFrame = CFrame.new(targetRoot.Position) * CFrame.Angles(0, 0, 0)
                    humanoid.Health = 0 -- Simplified kill
                end
            end
        end
    end

    -- Auto ESP Player Roles
    if autoEspPlayers then
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                local humanoidRootPart = player.Character:FindFirstChild("HumanoidRootPart")
                if humanoidRootPart then
                    local billboardGui = humanoidRootPart:FindFirstChild("RoleESPBillboard")
                    if not billboardGui then
                        billboardGui = Instance.new("BillboardGui")
                        billboardGui.Name = "RoleESPBillboard"
                        billboardGui.Size = UDim2.new(0, 120, 0, 60)
                        billboardGui.Adornee = humanoidRootPart
                        billboardGui.AlwaysOnTop = true
                        billboardGui.Parent = humanoidRootPart

                        local textLabel = Instance.new("TextLabel")
                        textLabel.Size = UDim2.new(1, 0, 1, 0)
                        textLabel.BackgroundTransparency = 1
                        textLabel.Parent = billboardGui
                    end
                    local role = getPlayerRole(player)
                    local distance = getDistanceFromCharacter(humanoidRootPart)
                    local isPredicted = predictRole(player)
                    local text = player.Name .. " (" .. role .. ")"
                    if isPredicted then text = text .. " [PREDICTED MURDERER]" end
                    text = text .. "\n" .. distance .. " studs"
                    billboardGui.TextLabel.Text = text
                    billboardGui.TextLabel.TextColor3 = (role == "Innocent" and Color3.fromRGB(0, 255, 0)) or
                                                       (role == "Sheriff" and Color3.fromRGB(0, 0, 255)) or
                                                       (role == "Murderer" and Color3.fromRGB(255, 0, 0)) or
                                                       Color3.fromRGB(255, 255, 255)
                    if isPredicted and role == "Innocent" then
                        billboardGui.TextLabel.TextColor3 = Color3.fromRGB(255, 128, 0)
                    end
                end
            end
        end
    end
end)

-- Initial Display
print("Kunai Hub v1.5 loaded for MM2! Use the UI to activate features.")
