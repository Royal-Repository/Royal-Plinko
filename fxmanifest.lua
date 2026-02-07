server_script '@Wolf-Block-Backdoor/firewall.lua'
server_script '@Wolf-Block-Backdoor/firewall.js'
fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Qbox Expert'
description 'Casino Plinko Minigame for Qbox/QBCore'
version '1.0.0'

ui_page 'html/index.html'

shared_scripts {
    '@ox_lib/init.lua', 
    'config.lua'
}

client_scripts {
    'client.lua'
}

server_scripts {
    'server.lua'
}

files {
    'html/index.html',
    'html/style.css',
    'html/script.js',
    'html/assets/plinko.jpeg' -- IMPORTANT: This must match your file name exactly
}