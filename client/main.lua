local CurrentBooth = nil
local InBoothRange = false
local TextUIShown = false
local UIOpen = false

local function GetBoothById(boothId)
    for _, booth in ipairs(Config.Booths) do
        if booth.id == boothId then
            return booth
        end
    end
    return nil
end

CreateThread(function()
    SetNuiFocus(false, false)
    SendNUIMessage({ type = "forceClose" })
end)

local function WaitForFrameworkReady()
    while not Framework.IsPlayerLoggedIn() do
        Wait(500)
    end
end

CreateThread(function()
    WaitForFrameworkReady()

    while true do
        local sleep = 1000
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        local foundBooth = nil

        for _, booth in ipairs(Config.Booths) do
            local distance = #(coords - booth.coords)
            if distance <= booth.radius then
                sleep = 0
                foundBooth = booth
                break
            end
        end

        if foundBooth then
            if not TextUIShown and not UIOpen then
                lib.showTextUI('[E] - ' .. (foundBooth.label or 'DJ Booth'), {
                    position = Config.UI.menuPosition
                })
                TextUIShown = true
            end

            InBoothRange = true
            CurrentBooth = foundBooth

            if IsControlJustReleased(0, 38) and not UIOpen then
                OpenDJUI(foundBooth)
            end
        else
            if TextUIShown then
                lib.hideTextUI()
                TextUIShown = false
            end
            InBoothRange = false
            CurrentBooth = nil
        end

        Wait(sleep)
    end
end)

function OpenDJUI(booth)
    lib.callback('dnr:server:checkBoothStatus', false, function(status)
        if status == "no_job" then
            lib.notify({
                title = 'DJ System',
                description = Config.Strings.noPermission,
                type = 'error',
                duration = 3000
            })
            return
        end

        if status == "in_use" then
            lib.notify({
                title = 'DJ System',
                description = Config.Strings.boothInUse,
                type = 'error',
                duration = 3000
            })
            return
        end

        UIOpen = true
        SetNuiFocus(true, true)
        SendNUIMessage({ type = 'open' })

        lib.callback('dnr:server:getPlaylists', false, function(playlists, songs)
            SendNUIMessage({
                type = 'getPlaylists',
                playlists = playlists or {},
                songs = songs or {}
            })
        end, booth.id)

        lib.callback('dnr:server:getSongInfo', false, function(songInfo)
            if songInfo and songInfo.url and songInfo.maxDuration then
                SendNUIMessage({
                    type = 'updateSonginfos',
                    link = songInfo.url,
                    maxDuration = songInfo.maxDuration
                })
            end
        end, booth.id)
    end, booth.id)
end

local function CloseDJUI()
    UIOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ type = "forceClose" })

    if not TextUIShown and InBoothRange and CurrentBooth then
        lib.showTextUI('[E] - ' .. (CurrentBooth.label or 'DJ Booth'), {
            position = Config.UI.menuPosition
        })
        TextUIShown = true
    end
end

RegisterNUICallback('close', function(_, cb)
    CloseDJUI()
    cb('ok')
end)

RegisterNUICallback('togglePlaystate', function(_, cb)
    if not CurrentBooth then cb('error') return end
    TriggerServerEvent('dnr:server:togglePause', CurrentBooth.id)
    cb('ok')
end)

RegisterNUICallback('playNewSong', function(data, cb)
    if not CurrentBooth then cb('error') return end
    local url = data.link
    if not url or url == '' then cb('error') return end

    lib.callback('dnr:server:playVideo', false, function(success, songInfo)
        if success then
            lib.notify({
                title = 'DJ System',
                description = Config.Strings.songPlaying:gsub('{song}', songInfo.title or 'Unknown'),
                type = 'success',
                duration = 5000
            })

            SendNUIMessage({
                type = 'updateSonginfos',
                link = songInfo.url,
                maxDuration = songInfo.duration or 0
            })
        else
            lib.notify({
                title = 'DJ System',
                description = Config.Strings.invalidUrl,
                type = 'error',
                duration = 3000
            })
        end
        cb('ok')
    end, CurrentBooth.id, url)
end)

RegisterNUICallback('rewind', function(_, cb)
    if not CurrentBooth then cb('error') return end
    TriggerServerEvent('dnr:server:rewind', CurrentBooth.id)
    cb('ok')
end)

RegisterNUICallback('forward', function(_, cb)
    if not CurrentBooth then cb('error') return end
    TriggerServerEvent('dnr:server:forward', CurrentBooth.id)
    cb('ok')
end)

RegisterNUICallback('down', function(_, cb)
    if not CurrentBooth then cb('error') return end
    TriggerServerEvent('dnr:server:adjustVolumeStep', CurrentBooth.id, -0.05)
    cb('ok')
end)

RegisterNUICallback('up', function(_, cb)
    if not CurrentBooth then cb('error') return end
    TriggerServerEvent('dnr:server:adjustVolumeStep', CurrentBooth.id, 0.05)
    cb('ok')
end)

RegisterNUICallback('addPlayList', function(data, cb)
    if not CurrentBooth then cb('error') return end
    TriggerServerEvent('dnr:server:addPlaylist', CurrentBooth.id, data.id, data.name)
    cb('ok')
end)

RegisterNUICallback('addSongToPlaylist', function(data, cb)
    if not CurrentBooth then cb('error') return end
    TriggerServerEvent('dnr:server:addSongToPlaylist', CurrentBooth.id, data.id, data.link)
    cb('ok')
end)

RegisterNUICallback('deleteSong', function(data, cb)
    if not CurrentBooth then cb('error') return end
    TriggerServerEvent('dnr:server:deleteSong', CurrentBooth.id, data.playlistId, data.id)
    cb('ok')
end)

RegisterNUICallback('deletePlaylist', function(data, cb)
    if not CurrentBooth then cb('error') return end
    TriggerServerEvent('dnr:server:deletePlaylist', CurrentBooth.id, data.id)
    cb('ok')
end)

RegisterNUICallback('playSongFromPlaylist', function(data, cb)
    if not CurrentBooth then cb('error') return end
    TriggerServerEvent('dnr:server:playSongFromPlaylist', CurrentBooth.id, data.playlistId, data.id, data.link)
    cb('ok')
end)

RegisterNUICallback('noSongtitle', function(_, cb)
    lib.notify({
        title = 'DJ System',
        description = Config.Strings.noTitle,
        type = 'error',
        duration = 3000
    })
    cb('ok')
end)

RegisterNetEvent('dnr:client:updateSound', function(boothId, soundData, action)
    local booth = GetBoothById(boothId)
    if not booth then return end

    local soundId = tostring(boothId)
    soundData = soundData or {}

    local function soundExists()
        return exports.xsound:soundExists(soundId) == true
    end

    if action == 'play' then
        if soundExists() then
            exports.xsound:Destroy(soundId)
        end

        if not soundData.url then return end

        local vol = soundData.volume or booth.volume or Config.XSound.defaultVolume

        exports.xsound:PlayUrlPos(
            soundId,
            soundData.url,
            vol,
            booth.coords,
            Config.XSound.useSpatialAudio,
            Config.XSound.loopEnabled
        )

        exports.xsound:Distance(soundId, booth.streamRadius or 50.0)
        exports.xsound:Position(soundId, booth.coords)
        return
    end

    if action == 'stop' then
        if soundExists() then
            exports.xsound:Destroy(soundId)
        end
        return
    end

    if action == 'volume' then
        if soundExists() and soundData.volume then
            exports.xsound:setVolume(soundId, soundData.volume)
        end
        return
    end

    if action == 'pause' then
        if not soundExists() then return end
        exports.xsound:Pause(soundId)
        return
    end

    if action == 'resume' then
        if not soundExists() then return end
        exports.xsound:Resume(soundId)
        return
    end
end)

RegisterNetEvent('dnr:client:updateSeconds', function(boothId, secs, maxDuration)
    if not UIOpen or not CurrentBooth or CurrentBooth.id ~= boothId then return end
    SendNUIMessage({
        type = 'updateSeconds',
        secs = secs,
        maxDuration = maxDuration
    })
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end

    if TextUIShown then
        lib.hideTextUI()
    end

    SetNuiFocus(false, false)
    SendNUIMessage({ type = "forceClose" })
end)

