fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'cfx-crp-changephonenumber'
author 'Caucasus RP / refie'
description 'LB-Phone Admin Phone Number Changer (/nomredeyisdir)'
version '1.0.0'

shared_scripts {
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
    'oxmysql'
}
