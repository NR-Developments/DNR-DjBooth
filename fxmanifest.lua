fx_version 'cerulean'
game 'gta5'

author 'Tommy'
description 'DNR DJ Booth System with Advanced Playlist UI'
version '4.0.0'

lua54 'yes'

ui_page 'html/ui.html'

files {
    'html/ui.html',
    'html/style.css',
    'html/script.js',
    'html/logo.png',
    'html/img/djpult.png'
}

shared_scripts {
    '@ox_lib/init.lua',
    'shared/framework.lua',
    'config.lua'
}

client_scripts {
    'client/main.lua',
    'client/menu.lua'
}

server_scripts {
    'server/main.lua'
}

dependencies {
    'ox_lib',
    'xsound'
}
