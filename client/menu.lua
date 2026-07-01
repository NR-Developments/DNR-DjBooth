function ShowLoadingProgress(title, duration)
    if lib.progressBar({
        duration = duration,
        label = title,
        useWhileDead = false,
        canCancel = true,
        disable = {
            car = true,
            combat = true
        }
    }) then
        return true
    else
        lib.notify({
            title = 'DJ System',
            description = 'Action cancelled',
            type = 'error',
            duration = 3000
        })
        return false
    end
end

function ShowCurrentSongInfo(songInfo)
    if not songInfo or not songInfo.title then return end

    local options = {
        {
            title = 'Now Playing',
            description = songInfo.title,
            icon = 'music'
        }
    }

    if songInfo.duration then
        table.insert(options, {
            title = 'Duration',
            description = FormatTime(songInfo.duration),
            icon = 'clock'
        })
    end

    if songInfo.channel then
        table.insert(options, {
            title = 'Channel',
            description = songInfo.channel,
            icon = 'user'
        })
    end

    lib.registerContext({
        id = 'song_info_menu',
        title = 'Current Track',
        options = options
    })

    lib.showContext('song_info_menu')
end

function FormatTime(seconds)
    if not seconds then return 'Unknown' end
    local minutes = math.floor(seconds / 60)
    local remainingSeconds = math.floor(seconds % 60)
    return string.format('%02d:%02d', minutes, remainingSeconds)
end

function DebugBoothInfo()
    if not Config.Debug then return end

    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)

    for _, booth in ipairs(Config.Booths) do
        local distance = #(playerCoords - booth.coords)

        DrawText3D(booth.coords.x, booth.coords.y, booth.coords.z + 1.0,
            booth.label .. ' (' .. string.format('%.2f', distance) .. 'm)')

        if distance < 20.0 then
            DrawMarker(1, booth.coords.x, booth.coords.y, booth.coords.z - 1.0,
                0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                1.0, 1.0, 1.0,
                50, 205, 50, 100,
                false, true, 2, nil, nil, false)
        end
    end
end

function DrawText3D(x, y, z, text)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    if onScreen then
        SetTextScale(0.35, 0.35)
        SetTextFont(4)
        SetTextProportional(1)
        SetTextColour(255, 255, 255, 215)
        SetTextEntry('STRING')
        SetTextCentre(1)
        AddTextComponentString(text)
        DrawText(_x, _y)
        local factor = (string.len(text)) / 370
        DrawRect(_x, _y + 0.0125, 0.015 + factor, 0.03, 41, 11, 41, 68)
    end
end

if Config.Debug then
    CreateThread(function()
        while true do
            Wait(0)
            DebugBoothInfo()
        end
    end)
end

