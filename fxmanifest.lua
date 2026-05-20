fx_version 'cerulean'
game 'gta5'

name 'qb-skills'
author 'you'
description 'Skill system with F1 menu, gym, decay, and gameplay effects'
version '1.0.0'

lua54 'yes'

shared_scripts {
    '@ox_lib/init.lua',
    'shared/config.lua'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua'
}
