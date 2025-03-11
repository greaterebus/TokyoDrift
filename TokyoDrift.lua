-- TokyoDrift.lua
local TokyoDrift = CreateFrame("Frame")
local MUSIC_FILE = "Interface/AddOns/TokyoDrift/Tokyo.mp3"  -- Ensure correct path to the music file
local BUFF_NAME = "G-99 Breakneck"
local soundHandle = nil  -- Track sound handle
local dropdown

-- Ensure TokyoDriftDB is a global variable for SavedVariables
TokyoDriftDB = TokyoDriftDB or { enabled = true, channel = "Master"}

local function LoadSettings()
    if TokyoDriftDB and type(TokyoDriftDB) == "table" then
        MUSIC_ENABLED = TokyoDriftDB.enabled ~= nil and TokyoDriftDB.enabled or true
        MUSIC_CHANNEL = TokyoDriftDB.channel or "Master"
    else
        TokyoDriftDB = { enabled = true, channel = "Master" }
    end
end

local function SaveSettings()
    TokyoDriftDB.enabled = MUSIC_ENABLED
    TokyoDriftDB.channel = MUSIC_CHANNEL
end

local function HasBuff(buffName)
    local name = AuraUtil.FindAuraByName(buffName, "player", "HELPFUL")
    return name ~= nil
end

local function OnEvent(self, event, ...)
    if event == "ADDON_LOADED" then
        local addonName = ...
        if addonName == "TokyoDrift" then
            LoadSettings()
        end
        return
    elseif event == "PLAYER_LOGOUT" then
        SaveSettings()
        return
    end
    
    if not MUSIC_ENABLED then
        if soundHandle and type(soundHandle) == "number" then
            StopSound(soundHandle)
            soundHandle = nil
        end
        return
    end
    
    if HasBuff(BUFF_NAME) then
        if not soundHandle then  -- Only play if not already playing
            soundHandle = select(2, PlaySoundFile(MUSIC_FILE, MUSIC_CHANNEL))
        end
    else
        if soundHandle and type(soundHandle) == "number" then  -- Stop sound if buff is lost
            StopSound(soundHandle)
            soundHandle = nil
        end
    end
end

TokyoDrift:RegisterEvent("UNIT_AURA")
TokyoDrift:RegisterEvent("ADDON_LOADED")
TokyoDrift:RegisterEvent("PLAYER_LOGOUT")
TokyoDrift:SetScript("OnEvent", OnEvent)

-- Settings Menu
local function CreateOptionsPanel()
    local panel = CreateFrame("Frame", "TokyoDriftPanel", UIParent)
    panel.name = "Tokyo Drift"
    
    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("Tokyo Drift")
    
    local checkbox = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
    checkbox:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -10)
    checkbox.text = checkbox:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    checkbox.text:SetPoint("LEFT", checkbox, "RIGHT", 5, 0)
    checkbox.text:SetText("Enable Mount Music")
    checkbox:SetChecked(MUSIC_ENABLED)
    
    checkbox:SetScript("OnClick", function(self)
        MUSIC_ENABLED = self:GetChecked()
        SaveSettings()
        if not MUSIC_ENABLED and soundHandle and type(soundHandle) == "number" then
            StopSound(soundHandle)
            soundHandle = nil
        elseif MUSIC_ENABLED then
            OnEvent(nil, "UNIT_AURA")  -- Manually trigger to check buff immediately
        end
    end)
    
    dropdown = CreateFrame("Frame", "TokyoDriftChannelDropdown", panel, "UIDropDownMenuTemplate")
    dropdown:SetPoint("TOPLEFT", checkbox, "BOTTOMLEFT", -16, -10)
    
    local function OnSelect(self, arg1)
        MUSIC_CHANNEL = arg1
        TokyoDriftDB.channel = arg1
        SaveSettings()
        UIDropDownMenu_SetText(dropdown, "Audio Channel: " .. MUSIC_CHANNEL)
    end
    
    local function InitializeDropdown(self, level)
        local info = UIDropDownMenu_CreateInfo()
        local channels = { "Master", "SFX", "Music", "Ambience", "Dialog" }
        for _, channel in ipairs(channels) do
            info.text = channel
            info.arg1 = channel
            info.func = OnSelect
            info.checked = (MUSIC_CHANNEL == channel)
            UIDropDownMenu_AddButton(info, level)
        end
    end
    
    UIDropDownMenu_Initialize(dropdown, InitializeDropdown)
    UIDropDownMenu_SetWidth(dropdown, 150)
    UIDropDownMenu_SetText(dropdown, "Audio Channel: " .. (MUSIC_CHANNEL or "Master"))
    
    Settings.RegisterAddOnCategory(Settings.RegisterCanvasLayoutCategory(panel, "Tokyo Drift"))
end

CreateOptionsPanel()
