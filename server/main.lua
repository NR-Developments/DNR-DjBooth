local ActiveBooths = {}
local PlayerSessions = {}
local Playlists = {}

local function GetBoothById(boothId)
    for _, booth in ipairs(Config.Booths) do
        if booth.id == boothId then
            return booth
        end
    end
    return nil
end

local function PlayerHasJob(src, booth)
    if not booth.requireJob then
        return true
    end

    for _, group in ipairs(Config.Permissions.adminGroups) do
        if IsPlayerAceAllowed(src, ('group.%s'):format(group)) then
            return true
        end
    end

    local job = nil

    if ESX then
        local xPlayer = ESX.GetPlayerFromId(src)
        if xPlayer then job = xPlayer.job.name end
    end

    if QBCore then
        local Player = QBCore.Functions.GetPlayer(src)
        if Player then job = Player.PlayerData.job.name end
    end

    if exports.qbx_core then
        local Player = exports.qbx_core:GetPlayer(src)
        if Player then job = Player.PlayerData.job.name end
    end

    if not job then return false end

    for _, allowed in ipairs(booth.allowedJobs or {}) do
        if job == allowed then
            return true
        end
    end

    return false
end

CreateThread(function()
    Wait(1000)
    print(('[dnr-djbooth] Server ready with %d DJ booth(s)'):format(#Config.Booths))
end)

lib.callback.register('dnr:server:checkBoothStatus', function(source, boothId)
    local booth = GetBoothById(boothId)
    if not booth then return "invalid" end

    if not PlayerHasJob(source, booth) then
        return "no_job"
    end

    local boothData = ActiveBooths[boothId]
    if boothData and boothData.active and boothData.player ~= source then
        return "in_use"
    end

    return false
end)

lib.callback.register('dnr:server:getPlaylists', function(source, boothId)
    Playlists[boothId] = Playlists[boothId] or { playlists = {}, songs = {} }
    return Playlists[boothId].playlists, Playlists[boothId].songs
end)

lib.callback.register('dnr:server:getSongInfo', function(source, boothId)
    local boothData = ActiveBooths[boothId]
    if not boothData or not boothData.active then
        return nil
    end
    return boothData.songInfo
end)

lib.callback.register('dnr:server:playVideo', function(source, boothId, youtubeUrl)
    local booth = GetBoothById(boothId)
    if not booth then return false end

    local isValid = false
    if booth.whitelistedUrls and #booth.whitelistedUrls > 0 then
        local lowerUrl = youtubeUrl:lower()
        for _, allowedUrl in ipairs(booth.whitelistedUrls) do
            if lowerUrl:find(allowedUrl:lower(), 1, true) then
                isValid = true
                break
            end
        end
    else
        isValid = true
    end

    if not isValid then
        lib.notify(source, {
            title = 'DJ System',
            description = Config.Strings.invalidUrl,
            type = 'error',
            duration = 3000
        })
        return false
    end

    local songInfo = {
        title       = 'YouTube Audio Stream',
        duration    = 300,
        channel     = 'Unknown',
        url         = youtubeUrl,
        maxDuration = booth.maxDuration or 900
    }

    if booth.maxDuration and songInfo.duration > booth.maxDuration then
        lib.notify(source, {
            title = 'DJ System',
            description = Config.Strings.maxDuration:gsub('{duration}', tostring(booth.maxDuration)),
            type = 'error',
            duration = 3000
        })
        return false
    end

    ActiveBooths[boothId] = {
        active      = true,
        player      = source,
        songInfo    = songInfo,
        volume      = booth.volume or Config.XSound.defaultVolume,
        startTime   = os.time(),
        paused      = false,
        elapsed     = 0,
        initializing = true
    }

    PlayerSessions[source] = boothId

    TriggerClientEvent('dnr:client:updateSound', -1, boothId, {
        url = youtubeUrl,
        volume = ActiveBooths[boothId].volume
    }, 'play')

    CreateThread(function()
        Wait(1200)
        if ActiveBooths[boothId] then
            ActiveBooths[boothId].initializing = false
        end
    end)

    lib.notify(source, {
        title = 'DJ System',
        description = Config.Strings.songPlaying:gsub('{song}', songInfo.title),
        type = 'success',
        duration = 3000
    })

    CreateThread(function()
        local id = boothId
        while ActiveBooths[id] and ActiveBooths[id].active do
            Wait(1000)
            local data = ActiveBooths[id]
            if data and not data.paused then
                data.elapsed = data.elapsed + 1
                TriggerClientEvent('dnr:client:updateSeconds', -1, id, data.elapsed, songInfo.maxDuration)
                if data.elapsed >= songInfo.maxDuration then
                    TriggerEvent('dnr:server:stopVideo', id, true)
                    break
                end
            end
        end
    end)

    return true, songInfo
end)

RegisterNetEvent('dnr:server:stopVideo', function(boothId, internal)
    local src = source
    if internal == true then src = 0 end

    local boothData = ActiveBooths[boothId]
    if not boothData or not boothData.active then return end

    TriggerClientEvent('dnr:client:updateSound', -1, boothId, nil, 'stop')
    TriggerClientEvent('dnr:client:updateSeconds', -1, boothId, 0, boothData.songInfo.maxDuration)

    boothData.active = false
    boothData.player = nil
    boothData.paused = false

    for player, bId in pairs(PlayerSessions) do
        if bId == boothId then
            PlayerSessions[player] = nil
        end
    end

    if src ~= 0 then
        lib.notify(src, {
            title = 'DJ System',
            description = Config.Strings.songStopped,
            type = 'info',
            duration = 3000
        })
    end
end)

RegisterNetEvent('dnr:server:adjustVolumeStep', function(boothId, step)
    local src = source
    local boothData = ActiveBooths[boothId]
    if not boothData or not boothData.active then return end

    if boothData.player ~= src then
        lib.notify(src, {
            title = 'DJ System',
            description = 'You cannot control this booth.',
            type = 'error',
            duration = 3000
        })
        return
    end

    local v = boothData.volume + step
    v = math.max(Config.XSound.minVolume, math.min(Config.XSound.maxVolume, v))
    boothData.volume = v

    TriggerClientEvent('dnr:client:updateSound', -1, boothId, { volume = v }, 'volume')
end)

RegisterNetEvent('dnr:server:togglePause', function(boothId)
    local src = source
    local boothData = ActiveBooths[boothId]
    if not boothData or not boothData.active then return end

    if boothData.initializing then
        print("[dnr-djbooth] Pause/Resume blocked — sound still initializing")
        return
    end

    if boothData.player ~= src then
        lib.notify(src, {
            title = 'DJ System',
            description = 'You cannot control this booth.',
            type = 'error',
            duration = 3000
        })
        return
    end

    boothData.paused = not boothData.paused

    if boothData.paused then
        TriggerClientEvent('dnr:client:updateSound', -1, boothId, nil, 'pause')
    else
        TriggerClientEvent('dnr:client:updateSound', -1, boothId, nil, 'resume')
    end
end)

RegisterNetEvent('dnr:server:rewind', function(boothId)
    local src = source
    local boothData = ActiveBooths[boothId]
    if not boothData or not boothData.active then return end
    if boothData.player ~= src then return end

    boothData.elapsed = math.max(0, boothData.elapsed - 10)
end)

RegisterNetEvent('dnr:server:forward', function(boothId)
    local src = source
    local boothData = ActiveBooths[boothId]
    if not boothData or not boothData.active then return end
    if boothData.player ~= src then return end

    boothData.elapsed = math.min(boothData.songInfo.maxDuration, boothData.elapsed + 10)
end)

RegisterNetEvent('dnr:server:addPlaylist', function(boothId, id, name)
    Playlists[boothId] = Playlists[boothId] or { playlists = {}, songs = {} }
    table.insert(Playlists[boothId].playlists, {
        id = id,
        label = name
    })
end)

RegisterNetEvent('dnr:server:addSongToPlaylist', function(boothId, playlistId, link)
    Playlists[boothId] = Playlists[boothId] or { playlists = {}, songs = {} }
    local songs = Playlists[boothId].songs
    local newId = #songs + 1
    table.insert(songs, {
        id = newId,
        playlist = playlistId,
        link = link,
        label = link
    })
end)

RegisterNetEvent('dnr:server:deleteSong', function(boothId, playlistId, songId)
    Playlists[boothId] = Playlists[boothId] or { playlists = {}, songs = {} }
    local songs = Playlists[boothId].songs
    for i = #songs, 1, -1 do
        if songs[i].id == songId and songs[i].playlist == playlistId then
            table.remove(songs, i)
        end
    end
end)

RegisterNetEvent('dnr:server:deletePlaylist', function(boothId, playlistId)
    Playlists[boothId] = Playlists[boothId] or { playlists = {}, songs = {} }
    local pl = Playlists[boothId].playlists
    for i = #pl, 1, -1 do
        if pl[i].id == playlistId then
            table.remove(pl, i)
        end
    end
    local songs = Playlists[boothId].songs
    for i = #songs, 1, -1 do
        if songs[i].playlist == playlistId then
            table.remove(songs, i)
        end
    end
end)

RegisterNetEvent('dnr:server:playSongFromPlaylist', function(boothId, playlistId, songId, link)
    local src = source
    local booth = GetBoothById(boothId)
    if not booth then return end

    local songInfo = {
        title       = 'Playlist Track',
        duration    = 300,
        channel     = 'Unknown',
        url         = link,
        maxDuration = booth.maxDuration or 900
    }

    ActiveBooths[boothId] = {
        active      = true,
        player      = src,
        songInfo    = songInfo,
        volume      = booth.volume or Config.XSound.defaultVolume,
        startTime   = os.time(),
        paused      = false,
        elapsed     = 0,
        initializing = true
    }

    PlayerSessions[src] = boothId

    TriggerClientEvent('dnr:client:updateSound', -1, boothId, {
        url = link,
        volume = ActiveBooths[boothId].volume
    }, 'play')

    CreateThread(function()
        Wait(1200)
        if ActiveBooths[boothId] then
            ActiveBooths[boothId].initializing = false
        end
    end)

    lib.notify(src, {
        title = 'DJ System',
        description = Config.Strings.songPlaying:gsub('{song}', songInfo.title),
        type = 'success',
        duration = 3000
    })

    CreateThread(function()
        local id = boothId
        while ActiveBooths[id] and ActiveBooths[id].active do
            Wait(1000)
            local data = ActiveBooths[id]
            if data and not data.paused then
                data.elapsed = data.elapsed + 1
                TriggerClientEvent('dnr:client:updateSeconds', -1, id, data.elapsed, songInfo.maxDuration)
                if data.elapsed >= songInfo.maxDuration then
                    TriggerEvent('dnr:server:stopVideo', id, true)
                    break
                end
            end
        end
    end)
end)

AddEventHandler('playerDropped', function()
    local src = source
    local boothId = PlayerSessions[src]
    if not boothId then return end

    local boothData = ActiveBooths[boothId]
    if not boothData or not boothData.active then return end

    TriggerClientEvent('dnr:client:updateSound', -1, boothId, nil, 'stop')
    TriggerClientEvent('dnr:client:updateSeconds', -1, boothId, 0, boothData.songInfo.maxDuration)

    boothData.active = false
    boothData.player = nil
    boothData.paused = false
    PlayerSessions[src] = nil
end)

RegisterCommand('stopalldj', function(source)
    if source ~= 0 then
        local isAdmin = false
        for _, group in ipairs(Config.Permissions.adminGroups) do
            if IsPlayerAceAllowed(source, ('group.%s'):format(group)) then
                isAdmin = true
                break
            end
        end

        if not isAdmin then
            lib.notify(source, {
                title = 'DJ System',
                description = 'You do not have permission.',
                type = 'error',
                duration = 3000
            })
            return
        end
    end

    for boothId, boothData in pairs(ActiveBooths) do
        if boothData.active then
            TriggerClientEvent('dnr:client:updateSound', -1, boothId, nil, 'stop')
            TriggerClientEvent('dnr:client:updateSeconds', -1, boothId, 0, boothData.songInfo.maxDuration)
            boothData.active = false
            boothData.player = nil
            boothData.paused = false
        end
    end

    PlayerSessions = {}

    if source ~= 0 then
        lib.notify(source, {
            title = 'DJ System',
            description = 'All DJ booths stopped.',
            type = 'success',
            duration = 3000
        })
    end
end, false)

