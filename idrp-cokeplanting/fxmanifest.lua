fx_version 'cerulean'

game 'gta5'

version '1.0'

description 'Coke Planting script'

shared_scripts {
	'shared/sh_shared.lua',
	'shared/locales.lua',
}

client_scripts{
	'@PolyZone/client.lua',
	'@PolyZone/CircleZone.lua',
	'client/cl_planting.lua'
}
server_script {
	'@oxmysql/lib/MySQL.lua',
	'server/sv_planting.lua'
}

dependencies {
	'PolyZone',
	'qb-target'
}

lua54 'yes'