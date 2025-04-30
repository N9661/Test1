-- Load the Fluent UI library
local Library = loadstring(game:HttpGetAsync("https://github.com/ActualMasterOogway/Fluent-Renewed/releases/latest/download/Fluent.luau"))()
local SaveManager = loadstring(game:HttpGetAsync("https://raw.githubusercontent.com/ActualMasterOogway/Fluent-Renewed/master/Addons/SaveManager.luau"))()
local InterfaceManager = loadstring(game:HttpGetAsync("https://raw.githubusercontent.com/ActualMasterOogway/Fluent-Renewed/master/Addons/InterfaceManager.luau"))()

-- Make Library accessible globally for notifications
getgenv().Library = Library

-- Load our whitelist system
local WhitelistSystem = loadstring(game:HttpGetAsync("https://raw.githubusercontent.com/N9661/Test1/refs/heads/main/WWhitelist.lua"))():Initialize()

-- Check if player is whitelisted
local isWhitelisted, whitelistMethod, identifiers = WhitelistSystem:IsWhitelisted()

if not isWhitelisted then
    -- Not whitelisted, show error and kick
    Library:Notify{
        Title = "Access Denied",
        Content = "You are not authorized to use this script.",
        SubContent = "Contact the developer for access.",
        Duration = 5
    }
    
    -- Wait a bit before kicking to show the notification
    task.wait(5)
    game.Players.LocalPlayer:Kick("Not authorized to use this script.")
    return
end

-- Continue with the script if whitelisted
local Window = Library:CreateWindow{
    Title = `Fluent {Library.Version}`,
    SubTitle = "by Actual Master Oogway",
    TabWidth = 160,
    Size = UDim2.fromOffset(830, 525),
    Resize = true,
    MinSize = Vector2.new(470, 380),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.RightControl
}

-- Create tabs
local Tabs = {
    Main = Window:CreateTab{
        Title = "Main",
        Icon = "phosphor-users-bold"
    },
    Security = Window:CreateTab{
        Title = "Security",
        Icon = "shield-check"
    },
    Settings = Window:CreateTab{
        Title = "Settings",
        Icon = "settings"
    }
}

local Options = Library.Options

-- Add security information to the Security tab
Tabs.Security:CreateParagraph("SecurityInfo", {
    Title = "Security Information",
    Content = "Authentication Method: " .. whitelistMethod,
    TitleAlignment = "Middle",
    ContentAlignment = Enum.TextXAlignment.Center
})

Tabs.Security:CreateParagraph("UserInfo", {
    Title = "User Information",
    Content = "Username: " .. identifiers.Username .. 
              "\nUserID: " .. identifiers.UserID .. 
              "\nHWID: " .. string.sub(identifiers.HWID, 1, 8) .. "..." .. 
              "\nSession ID: " .. string.sub(identifiers.ClientID, 1, 8) .. "..."
})

-- Welcome notification
Library:Notify{
    Title = "Welcome",
    Content = "Successfully authenticated!",
    SubContent = "Welcome, " .. identifiers.Username,
    Duration = 5
}

-- Continue with your original UI code
-- ...

-- Addons
SaveManager:SetLibrary(Library)
InterfaceManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes{}
InterfaceManager:SetFolder("FluentScriptHub")
SaveManager:SetFolder("FluentScriptHub/specific-game")
InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)
Window:SelectTab(1)

-- Load configs
SaveManager:LoadAutoloadConfig()

-- Clean up when the script is unloaded
game:GetService("Players").LocalPlayer.OnTeleport:Connect(function()
    WhitelistSystem:Cleanup()
end)
