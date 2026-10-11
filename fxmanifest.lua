-- Developed by rafializade
fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'lb-phone-changenumber'
description 'Live phone number changer for LB-Phone'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

client_scripts {
    'client/client.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/server.lua'
}

dependencies {
    'oxmysql',
    'ox_lib'
}
