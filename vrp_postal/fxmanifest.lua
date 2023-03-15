fx_version 'cerulean'
games { 'rdr3', 'gta5' }

dependency "vrp"

server_scripts {
	"@vrp/lib/utils.lua",
	"vrp.lua"
}

client_scripts {
	"@vrp/lib/utils.lua",
	"client.lua"
}
