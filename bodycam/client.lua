-- ===============================
-- CORE STATE
-- ===============================
local isBWVOn = false
local isShowingAxon = false
local isShowingReveal = false

-- Auto trigger control
local lastSirenState = false
local pendingAutoStart = false
local autoTriggered = false

-- ===============================
-- POLICE VEHICLE CHECK
-- ===============================
local function IsPoliceVehicle(vehicle)
    if vehicle == 0 then return false end
    return GetVehicleClass(vehicle) == 18 -- Emergency vehicles
end

-- ===============================
-- LEGACY NOTIFY (COMPATIBILITY)
-- ===============================
function Notify(text)
    SetNotificationTextEntry("STRING")
    AddTextComponentString(text)
    DrawNotification(false, true)
end

-- ===============================
-- TIMED NOTIFICATION (AUTO CLEAR)
-- ===============================
local function TimedNotify(text, duration)
    BeginTextCommandThefeedPost("STRING")
    AddTextComponentSubstringPlayerName(text)
    local notif = EndTextCommandThefeedPostTicker(false, true)

    Citizen.SetTimeout(duration or 4000, function()
        ThefeedRemoveItem(notif)
    end)
end

-- ===============================
-- MANUAL BODYCAM TOGGLE
-- (ANIMATION UNCHANGED)
-- ===============================
RegisterCommand("bodycam", function()
    local ped = PlayerPedId()

    while not HasAnimDictLoaded("clothingtie") do
        RequestAnimDict("clothingtie")
        Citizen.Wait(0)
    end

    ClearPedTasks(ped)
    TaskPlayAnim(
        ped,
        "clothingtie",
        "outro",
        8.0,
        2.0,
        1880,
        51,
        2.0,
        0,
        0,
        0
    )

    if isBWVOn then
        TimedNotify("~w~{~y~AXON~w~} Body Camera turned ~r~OFF", 3000)
        TriggerEvent('IFS:PlaySound', Config.Model .. '_out')
        isBWVOn = false
        autoTriggered = false
    else
        TimedNotify("~w~{~y~AXON~w~} Body Camera turned ~g~ON", 3000)
        TriggerEvent('IFS:PlaySound', Config.Model .. '_in')
        isBWVOn = true
    end
end, false)

RegisterKeyMapping(
    "bodycam",
    "Toggle Axon Bodycam",
    "keyboard",
    "O"
)

-- ===============================
-- AUTO BODYCAM (TRIGGER ONLY)
-- ===============================
Citizen.CreateThread(function()
    while true do
        local ped = PlayerPedId()
        local sirenActive = false
        local veh = 0

        if IsPedInAnyVehicle(ped, false) then
            veh = GetVehiclePedIsIn(ped, false)
            if IsPoliceVehicle(veh) then
                sirenActive =
                    IsVehicleSirenOn(veh) or
                    IsVehicleSirenAudioOn(veh) or
                    IsVehicleSirenSoundOn(veh)
            end
        end

        -- OFF ? ON (single trigger only)
        if sirenActive and not lastSirenState and not pendingAutoStart and not autoTriggered then
            pendingAutoStart = true
            local triggerVehicle = veh

            Citizen.SetTimeout(2500, function()
                if not autoTriggered
                    and DoesEntityExist(triggerVehicle)
                    and IsPoliceVehicle(triggerVehicle)
                    and (
                        IsVehicleSirenOn(triggerVehicle)
                        or IsVehicleSirenAudioOn(triggerVehicle)
                        or IsVehicleSirenSoundOn(triggerVehicle)
                    )
                    and not isBWVOn then

                    isBWVOn = true
                    autoTriggered = true

                    TimedNotify(
                        "~w~{~y~AXON~w~}\n~o~Signal Vehicle:\n~r~Emergency lights activated\n~g~Body camera recording",
                        4500
                    )

                    TriggerEvent('IFS:PlaySound', Config.Model .. '_in')
                end

                pendingAutoStart = false
            end)
        end

        lastSirenState = sirenActive
        Citizen.Wait(300)
    end
end)

-- ===============================
-- NUI SOUND HANDLER
-- ===============================
AddEventHandler('IFS:PlaySound', function(soundFile)
    SendNUIMessage({
        transactionType = 'playSound',
        transactionFile = soundFile,
        transactionVolume = Config.soundVolume
    })
end)

-- ===============================
-- AXON / REVEAL UI + TIMESTAMP
-- ===============================
Citizen.CreateThread(function()
    while true do
        if isBWVOn then
            local y, m, d, h, min, s = GetLocalTime()
            if m < 10 then m = "0" .. m end
            if d < 10 then d = "0" .. d end

            if Config.Model == 'axon' then
                if not isShowingAxon then
                    SendNUIMessage({
                        transactionType = 'showAxon',
                        show = true,
                        timestamp = y .. '-' .. m .. '-' .. d .. ' T' .. h .. ':' .. min .. ':' .. s
                    })
                    isShowingAxon = true
                end

                SendNUIMessage({
                    transactionType = 'updateTime',
                    timestamp = y .. '-' .. m .. '-' .. d .. ' T' .. h .. ':' .. min .. ':' .. s
                })
            end

            if Config.Model == 'reveal' then
                if not isShowingReveal then
                    SendNUIMessage({
                        transactionType = 'showReveal',
                        show = true,
                        timestamp = y .. '/' .. m .. '/' .. d .. ' ' .. h .. ':' .. min .. ':' .. s
                    })
                    isShowingReveal = true
                end

                SendNUIMessage({
                    transactionType = 'updateTime',
                    timestamp = y .. '/' .. m .. '/' .. d .. ' ' .. h .. ':' .. min .. ':' .. s
                })
            end
        else
            if isShowingAxon then
                SendNUIMessage({ transactionType = 'showAxon', show = false })
                isShowingAxon = false
            end

            if isShowingReveal then
                SendNUIMessage({ transactionType = 'showReveal', show = false })
                isShowingReveal = false
            end
        end

        Citizen.Wait(100)
    end
end)
-- ===============================
-- BODYCAM AUDIBLE BEEP (2 MIN LOOP)
-- ===============================
local lastBodycamBeep = 0
local BODYCAM_BEEP_INTERVAL = 120000 -- 2 minutes (ms)
local BODYCAM_BEEP_DISTANCE = 3.0    -- ~10 feet
local BODYCAM_BEEP_VOLUME = 1.0      -- Loud

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1000)

        if isBWVOn then
            local now = GetGameTimer()

            if (now - lastBodycamBeep) >= BODYCAM_BEEP_INTERVAL then
                lastBodycamBeep = now

                local ped = PlayerPedId()
                local coords = GetEntityCoords(ped)

                -- Play 3D proximity sound for nearby players
                TriggerServerEvent(
                    "PlayCustomSounds:Server:PlayWithinDistance",
                    BODYCAM_BEEP_DISTANCE,
                    "beep",
                    BODYCAM_BEEP_VOLUME
                )
            end
        else
            -- Reset timer when bodycam turns off
            lastBodycamBeep = 0
        end
    end
end)

