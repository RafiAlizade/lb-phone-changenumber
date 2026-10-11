-- Developed by rafializade

local Core = nil
local Framework = 'standalone'
local IsQbox = false

local function Msg(key, ...)
    local lang = Config.Locale or 'en'
    local dict = Config.Messages[lang] or Config.Messages['en'] or Config.Messages['az']
    local text = dict[key] or key
    if select('#', ...) > 0 then
        return string.format(text, ...)
    end
    return text
end

local function InitFramework()
    local fw = (Config.Framework or 'auto'):lower()

    if (fw == 'auto' or fw == 'qbox') and GetResourceState('qbx_core') == 'started' then
        Framework = 'qbox'
        IsQbox = true
        Core = exports['qbx_core']
    elseif (fw == 'auto' or fw == 'qb' or fw == 'qbcore') and GetResourceState('qb-core') == 'started' then
        Framework = 'qb'
        Core = exports['qb-core']:GetCoreObject()
    elseif (fw == 'auto' or fw == 'esx') and GetResourceState('es_extended') == 'started' then
        Framework = 'esx'
        Core = exports['es_extended']:getSharedObject()
    end
end

CreateThread(function()
    InitFramework()
end)

local function GetPlayer(src)
    if not src or src <= 0 then return nil end

    if IsQbox then
        return exports.qbx_core:GetPlayer(src)
    elseif Framework == 'qb' and Core then
        return Core.Functions.GetPlayer(src)
    elseif Framework == 'esx' and Core then
        return Core.GetPlayerFromId(src)
    end

    return nil
end

local function GetIdentifier(src, player)
    player = player or GetPlayer(src)
    if not player then
        return GetPlayerIdentifierByType(src, 'license')
    end

    if player.PlayerData and player.PlayerData.citizenid then
        return player.PlayerData.citizenid
    elseif player.identifier then
        return player.identifier
    end

    return GetPlayerIdentifierByType(src, 'license')
end

local function GetPlayerNameFormatted(src, player)
    player = player or GetPlayer(src)
    if player then
        if player.PlayerData and player.PlayerData.charinfo then
            local c = player.PlayerData.charinfo
            return (c.firstname or '') .. ' ' .. (c.lastname or '')
        elseif player.getName then
            return player.getName()
        end
    end
    return GetPlayerName(src) or 'Unknown'
end

local function Notify(src, message, msgType)
    if src == 0 then
        local color = (msgType == 'error') and '^1' or ((msgType == 'success') and '^2' or '^3')
        print(color .. message .. '^7')
        return
    end

    TriggerClientEvent('lb-phone-changenumber:client:notify', src, message, msgType or 'inform')
end

local function ExecuteChangeNumber(source, args)
    -- 1. Target Player Check
    local targetSrc = args.id
    local targetPlayer = GetPlayer(targetSrc)
    if not targetPlayer then
        Notify(source, Msg('player_not_found'), 'error')
        return
    end

    -- 2. New Phone Number Validation
    local newNumber = tostring(args.nomre):gsub('%s+', '')
    if not string.match(newNumber, '^%d+$') then
        Notify(source, Msg('invalid_number'), 'error')
        return
    end

    local identifier = GetIdentifier(targetSrc, targetPlayer)

    -- 3. Retrieve Target Phone from phone_phones
    local currentPhone = nil

    -- a) Query active equipped phone number in LB-Phone
    if GetResourceState('lb-phone') == 'started' then
        pcall(function()
            local equippedNumber = exports['lb-phone']:GetEquippedPhoneNumber(targetSrc)
            if equippedNumber and equippedNumber ~= '' then
                currentPhone = MySQL.single.await(
                    'SELECT id, owner_id, phone_number FROM phone_phones WHERE phone_number = ? LIMIT 1',
                    { equippedNumber })
            end
        end)
    end

    -- b) Fallback lookup by owner_id (CitizenID/Identifier)
    if not currentPhone and identifier then
        currentPhone = MySQL.single.await(
            'SELECT id, owner_id, phone_number FROM phone_phones WHERE owner_id = ? ORDER BY last_seen DESC LIMIT 1',
            { identifier })
    end

    -- c) Fallback lookup by id
    if not currentPhone and identifier then
        currentPhone = MySQL.single.await(
            'SELECT id, owner_id, phone_number FROM phone_phones WHERE id = ? LIMIT 1',
            { identifier })
    end

    if not currentPhone then
        Notify(source, Msg('phone_not_found'), 'error')
        return
    end

    local oldNumber = currentPhone.phone_number

    -- 4. Check for Identical Number
    if oldNumber == newNumber then
        Notify(source, Msg('same_number', oldNumber), 'error')
        return
    end

    -- 5. Check if Number is Taken by Another Player
    local exists = MySQL.scalar.await('SELECT 1 FROM phone_phones WHERE phone_number = ? LIMIT 1', { newNumber })
    if exists and exists > 0 then
        Notify(source, Msg('number_taken', newNumber), 'error')
        return
    end

    -- 6. Database Updates
    -- a) Update primary phone record in phone_phones
    local updated = MySQL.update.await('UPDATE phone_phones SET phone_number = ? WHERE id = ?',
        { newNumber, currentPhone.id })
    if not updated or updated <= 0 then
        MySQL.update.await('UPDATE phone_phones SET phone_number = ? WHERE phone_number = ?', { newNumber, oldNumber })
    end

    -- b) Update phone_last_phone
    pcall(function()
        MySQL.update.await('UPDATE phone_last_phone SET phone_number = ? WHERE phone_number = ?',
            { newNumber, oldNumber })
    end)

    -- c) Update framework database (players charinfo JSON / users table)
    if identifier then
        if IsQbox or Framework == 'qb' then
            pcall(function()
                MySQL.update.await("UPDATE players SET charinfo = JSON_SET(charinfo, '$.phone', ?) WHERE citizenid = ?",
                    { newNumber, identifier })
            end)
        elseif Framework == 'esx' then
            pcall(function()
                MySQL.update.await('UPDATE users SET phone_number = ? WHERE identifier = ?',
                    { newNumber, identifier })
            end)
        end
    end

    -- d) In-Memory PlayerData update
    if targetPlayer.PlayerData and targetPlayer.PlayerData.charinfo then
        targetPlayer.PlayerData.charinfo.phone = newNumber

        if IsQbox then
            pcall(function()
                exports.qbx_core:SetPlayerData(targetSrc, 'charinfo', targetPlayer.PlayerData.charinfo)
            end)
        elseif targetPlayer.Functions and targetPlayer.Functions.SetPlayerData then
            targetPlayer.Functions.SetPlayerData('charinfo', targetPlayer.PlayerData.charinfo)
        end

        if targetPlayer.Functions and targetPlayer.Functions.Save then
            targetPlayer.Functions.Save()
        end
    end

    -- 7. Sync State Bag & Live Reload LB-Phone
    Player(targetSrc).state:set('phoneNumber', newNumber, true)
    TriggerClientEvent('lb-phone-changenumber:client:reloadPhone', targetSrc, newNumber)

    -- 8. Notifications & Console Log
    local targetName = GetPlayerNameFormatted(targetSrc, targetPlayer)
    Notify(source, Msg('admin_success', targetName, targetSrc, newNumber), 'success')
    Notify(targetSrc, Msg('target_success', newNumber), 'inform')

    print(string.format(
        '^2[lb-phone-changenumber]^7 Admin (%s) updated phone number for %s (ID: %d): %s -> %s^7',
        tostring(source), targetName, targetSrc, oldNumber, newNumber
    ))
end

-- --------------------------------------------------------------------------
-- Command Registration (ox_lib addCommand)
-- --------------------------------------------------------------------------
local commandName = Config.Command or 'nomredeyisdir'
local commandParams = {
    help = Msg('command_help'),
    params = {
        { name = 'id',    type = 'playerId', help = Msg('param_id_help') },
        { name = 'nomre', type = 'string',   help = Msg('param_nomre_help') },
    },
    restricted = Config.Restricted or 'group.god',
}

lib.addCommand(commandName, commandParams, ExecuteChangeNumber)

if Config.Aliases and #Config.Aliases > 0 then
    for _, alias in ipairs(Config.Aliases) do
        lib.addCommand(alias, commandParams, ExecuteChangeNumber)
    end
end

-- --------------------------------------------------------------------------
-- Server Export
-- --------------------------------------------------------------------------
exports('ChangePhoneNumber', function(targetSrc, newNumber)
    local targetPlayer = GetPlayer(targetSrc)
    if not targetPlayer then return false, 'player_offline' end

    newNumber = tostring(newNumber):gsub('%s+', '')
    if not newNumber:match('^%d+$') then return false, 'invalid_number' end

    local identifier = GetIdentifier(targetSrc, targetPlayer)
    local currentPhone = nil

    if GetResourceState('lb-phone') == 'started' then
        pcall(function()
            local equippedNumber = exports['lb-phone']:GetEquippedPhoneNumber(targetSrc)
            if equippedNumber and equippedNumber ~= '' then
                currentPhone = MySQL.single.await('SELECT id, owner_id, phone_number FROM phone_phones WHERE phone_number = ? LIMIT 1', { equippedNumber })
            end
        end)
    end

    if not currentPhone and identifier then
        currentPhone = MySQL.single.await('SELECT id, owner_id, phone_number FROM phone_phones WHERE owner_id = ? ORDER BY last_seen DESC LIMIT 1', { identifier })
    end

    if not currentPhone and identifier then
        currentPhone = MySQL.single.await('SELECT id, owner_id, phone_number FROM phone_phones WHERE id = ? LIMIT 1', { identifier })
    end

    if not currentPhone then return false, 'phone_not_found' end

    local exists = MySQL.scalar.await('SELECT 1 FROM phone_phones WHERE phone_number = ? LIMIT 1', { newNumber })
    if exists and exists > 0 then return false, 'number_taken' end

    MySQL.update.await('UPDATE phone_phones SET phone_number = ? WHERE id = ?', { newNumber, currentPhone.id })
    pcall(function()
        MySQL.update.await('UPDATE phone_last_phone SET phone_number = ? WHERE phone_number = ?', { newNumber, currentPhone.phone_number })
    end)

    if identifier then
        if IsQbox or Framework == 'qb' then
            pcall(function()
                MySQL.update.await("UPDATE players SET charinfo = JSON_SET(charinfo, '$.phone', ?) WHERE citizenid = ?", { newNumber, identifier })
            end)
        elseif Framework == 'esx' then
            pcall(function()
                MySQL.update.await('UPDATE users SET phone_number = ? WHERE identifier = ?', { newNumber, identifier })
            end)
        end
    end

    if targetPlayer.PlayerData and targetPlayer.PlayerData.charinfo then
        targetPlayer.PlayerData.charinfo.phone = newNumber
        if IsQbox then
            pcall(function() exports.qbx_core:SetPlayerData(targetSrc, 'charinfo', targetPlayer.PlayerData.charinfo) end)
        elseif targetPlayer.Functions and targetPlayer.Functions.SetPlayerData then
            targetPlayer.Functions.SetPlayerData('charinfo', targetPlayer.PlayerData.charinfo)
        end
        if targetPlayer.Functions and targetPlayer.Functions.Save then targetPlayer.Functions.Save() end
    end

    Player(targetSrc).state:set('phoneNumber', newNumber, true)
    TriggerClientEvent('lb-phone-changenumber:client:reloadPhone', targetSrc, newNumber)

    return true, newNumber
end)
