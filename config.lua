Config = {}

Config.Debug = false

Config.UI = {
    menuPosition = 'right-center'
}

Config.XSound = {
    defaultVolume   = 0.3,
    minVolume       = 0.0,
    maxVolume       = 1.0,
    useSpatialAudio = true,
    loopEnabled     = false,
    streamBuffer    = 5000
}

Config.Strings = {
    boothInUse   = 'This DJ booth is currently in use.',
    invalidUrl   = 'Invalid or unsupported URL.',
    maxDuration  = 'This song is too long. Max duration is {duration} seconds.',
    songPlaying  = 'Now playing: {song}',
    songStopped  = 'Song stopped.',
    noTitle      = 'Could not fetch song title.',
    noPermission = 'You do not have permission to use this DJ booth.'
}

Config.Permissions = {
    adminGroups = { 'admin', 'god' }
}

Config.Booths = {
    {
        id = 1,
        label = 'Legion Hangout DJ Booth',
        coords = vec3(160.87, -1000.25, 28.35),
        radius = 3.0,
        streamRadius = 50.0,

        requireJob = false,
        allowedJobs = { 'dj', 'entertainer', 'musician' },

        volume = 0.3,
        maxDuration = 900,
        whitelistedUrls = { 'youtube.com', 'youtu.be' }
    },

    {
        id = 2,
        label = 'UwU Radio',
        coords = vec3(-584.33, -1068.55, 22.34),
        radius = 3.0,
        streamRadius = 50.0,

        requireJob = true,
        allowedJobs = { 'dj', 'entertainer', 'musician', 'uwu', 'lsc' },

        volume = 0.3,
        maxDuration = 900,
        whitelistedUrls = { 'youtube.com', 'youtu.be' }
    },

    {
        id = 3,
        label = 'Axels LSC Radio',
        coords = vec3(-319.47, -121.03, 39.01),
        radius = 3.0,
        streamRadius = 50.0,

        requireJob = true,
        allowedJobs = { 'dj', 'entertainer', 'musician', 'uwu', 'lsc' },

        volume = 0.3,
        maxDuration = 900,
        whitelistedUrls = { 'youtube.com', 'youtu.be' }
    },

    {
        id = 3,
        label = 'Don Romanos Radio',
        coords = vec3(-1197.09, -1404.52, 4.47),
        radius = 3.0,
        streamRadius = 50.0,

        requireJob = false,
        allowedJobs = { 'dj', 'entertainer', 'musician'},

        volume = 0.3,
        maxDuration = 900,
        whitelistedUrls = { 'youtube.com', 'youtu.be' }
    },
}


