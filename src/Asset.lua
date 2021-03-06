
module("Asset", package.seeall)

require("src/AudioManager")
--require("src/FieldAnimator")
--require("src/Hooker")

local InstancePolicy = AudioManager.InstancePolicy

-- assets

desc_root = {

font = {
	--main = {14, default = true},
	--presenter = {30, default = true},
	presenter = {36, path = "ropa-sans"},
},

atlas = {},

anim = {},

sound = {

-- player

	player_move
		= {InstancePolicy.Constant, limit = 4},
	player_spawn
		= {InstancePolicy.Reserve, limit = 5},
	player_killed
		= {InstancePolicy.Reserve, limit = 5},

-- triggers

	--trigger_message_activate
	--	 = {InstancePolicy.Constant, limit = 1},

-- Switch
	trigger_switch_activate_1
		= {InstancePolicy.Reserve, limit = 5},
	trigger_switch_activate_2
		= {InstancePolicy.Reserve, limit = 5},

-- Teleporter
	trigger_teleporter_activate
		= {InstancePolicy.Constant, limit = 4},

-- Timer
	trigger_timer_activate_1
		= {InstancePolicy.Constant, limit = 4},

-- Sink
	--trigger_sink_activate
	--	= {InstancePolicy.Constant, limit = 4},

},

-- NB: Preloading is done by AssetLoader; Data/World handle the
-- actual hot-loading
world = {}

} -- desc_root

-- hooklets
-- hooklet = {}
