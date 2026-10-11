-- Developed by rafializade

local Core = nil

local function Msg(key, ...)
    local lang = Config.Locale or 'en'
    local dict = Config.Messages[lang] or Config.Messages['en'] or Config.Messages['az']
    local text = dict[key] or key
    if select('#', ...) > 0 then
        return string.format(text, ...)
    end
    return text
end

CreateThread(function()
    if GetResourceState('qbx_core') == 'started' or GetResourceState('qb-core') == 'started' then
        if exports['qb-core'] then
            Core = exports['qb-core']:GetCoreObject()
        end
    elseif GetResourceState('es_extended') == 'started' then
        Core = exports['es_extended']:getSharedObject()
    end
end)

local function ShowNotification(message, msgType)
    msgType = msgType or 'inform'

    if msgType == 'success' then
        PlaySoundFrontend(-1, 'CHECKPOINT_PERFECT', 'HUD_MINI_GAME_SOUNDSET', true)
    elseif msgType == 'error' then
        PlaySoundFrontend(-1, 'ERROR', 'HUD_AMMO_SHOP_SOUNDSET', true)
    end

    local notifyMode = Config.Notify or 'auto'

    if (notifyMode == 'auto' or notifyMode == 'ox_lib') and GetResourceState('ox_lib') == 'started' then
        lib.notify({
            title = Msg('phone_title') or 'Phone System',
            description = message,
            type = msgType,
            position = 'top-right',
            duration = 5000
        })
    elseif (notifyMode == 'auto' or notifyMode == 'qb') and Core and Core.Functions and Core.Functions.Notify then
        Core.Functions.Notify(message, msgType, 5000)
    elseif (notifyMode == 'auto' or notifyMode == 'esx') and Core and Core.ShowNotification then
        Core.ShowNotification(message)
    else
        TriggerEvent('chat:addMessage', {
            color = { 0, 150, 255 },
            multiline = true,
            args = { 'SYSTEM', message }
        })
    end
end

RegisterNetEvent('lb-phone-changenumber:client:notify', function(message, msgType)
    ShowNotification(message, msgType)
end)

RegisterNetEvent('lb-phone-changenumber:client:reloadPhone', function(newNumber)
    if GetResourceState('lb-phone') == 'started' then
        exports['lb-phone']:ReloadPhone()

        if Config.SendPhoneNotification then
            pcall(function()
                exports['lb-phone']:SendNotification({
                    title = Msg('phone_title'),
                    content = Msg('phone_notif', newNumber),
                    icon = 'phone',
                    duration = 5000
                })
            end)
        end
    end
end)
