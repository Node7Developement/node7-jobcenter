fx_version 'cerulean'
game 'rdr3'

rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'

lua54 'yes'

author 'NODE7 Development Studios'
description 'RedM public employment board using NODE7 Core public jobs and direct exports.'
version '2.2.1'

ui_page 'html/index.html'

shared_scripts {
    'config.lua',
    'shared/integrations.lua'
}

client_scripts {
    'client/preload.lua',
    'client/main.lua'
}

server_scripts {
    'server/preload.lua',
    'server/main.lua'
}

files {
    'html/index.html',
    'html/style.css',
    'html/app.js'
}

dependencies {
    'node7-core',
    'node7-interaction'
}
