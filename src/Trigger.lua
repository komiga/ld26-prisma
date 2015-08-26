
module("Trigger", package.seeall)

require("src/Util")

require("src/Data")

GenericState = {
	Active = 1,
	Inactive = 2
}

function __trg_callback(world, trg)
	-- Util.debug("__trg_callback")
	return not trg.data.callback(world, trg)
end

require("src/Trigger/Message")
require("src/Trigger/ChangeWorld")
require("src/Trigger/Switch")
require("src/Trigger/Teleporter")
require("src/Trigger/Timer")
require("src/Trigger/Sink")

-- Trigger interface

local data = {
	__initialized = false
}

local instantiator = {
	[Data.TriggerType.Message] = Trigger.new_message,
	[Data.TriggerType.ChangeWorld] = Trigger.new_change_world,
	[Data.TriggerType.Switch] = Trigger.new_switch,
	[Data.TriggerType.Teleporter] = Trigger.new_teleporter,
	[Data.TriggerType.Timer] = Trigger.new_timer,
	[Data.TriggerType.Sink] = Trigger.new_sink,
}

function new(world, trd)
	Util.tcheck(trd, "table")
	Util.tcheck(trd.type, "number")
	Util.tcheck(trd.tx, "number")
	Util.tcheck(trd.ty, "number")
	Util.tcheck(trd.callback, "function")

	return instantiator[trd.type](world, trd)
end

function init()
	assert(not data.__initialized)
	data.__initialized = true
end
