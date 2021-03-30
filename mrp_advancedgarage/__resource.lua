resource_manifest_version '44febabe-d386-4d18-afbe-5e627f4af937'

description 'MRP Advanced Garage'

version '1.0.0'

server_scripts {
	'@mysql-async/lib/MySQL.lua',
	'@mrp-core/locale.lua',
	'locales/en.lua',
	'config.lua',
	'server/main.lua'
}

client_scripts {
	'@mrp-core/locale.lua',
	'locales/en.lua',
	'config.lua',
	'client/main.lua'
}








