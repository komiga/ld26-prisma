
module("Asset", package.seeall)

require("src/AudioManager")
require("src/FieldAnimator")
require("src/Hooker")

InstancePolicy=AudioManager.InstancePolicy

-- assets

desc_root={

font={
	-- TODO: get clean monospace font
	main={12, default=true},
	-- TODO: FIND ZE PRESENTER FONT
	presenter={30, default=true}
},

atlas={
	--[[sprites={
		indexed=true,
		size={32,32},
		tex={
			{"a", 0, 0},
			{"b", 32,0, 32,64}
		}
	}--]]
},

anim={},

sound={

-- player

	player_move
		={InstancePolicy.Constant, limit=4},
	player_spawn
		={InstancePolicy.Constant, limit=4},

-- triggers

	--trigger_message_activate
	--	={InstancePolicy.Constant, limit=1},

-- TODO: This thing SUCKS
	trigger_change_world_activate
		={InstancePolicy.Constant, limit=1},

	trigger_switch_activate_1
		={InstancePolicy.Reserve, limit=5},
	trigger_switch_activate_2
		={InstancePolicy.Reserve, limit=5},

	trigger_teleporter_activate
		={InstancePolicy.Constant, limit=1},
},

world={
	start={},
	a_bit_switchy={},
	--apples_to_me={},
	--bupkis={},
	--quack={},
	--circuit={},
}

} -- desc_root

-- hooklets
-- hooklet={}
