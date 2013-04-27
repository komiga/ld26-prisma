
module("Trigger", package.seeall)

require("src/Util")

require("src/Data")

GenericState={
	Active=1,
	Inactive=2
}

require("src/Trigger/Message")
require("src/Trigger/ChangeWorld")
require("src/Trigger/Switch")

-- Trigger interface

local data={
	__initialized=false
}

local TriggerInstantiator={
	[Data.TriggerType.Message]=Trigger.new_message,
	[Data.TriggerType.ChangeWorld]=Trigger.new_change_world,
	[Data.TriggerType.Switch]=Trigger.new_switch,
}

function new(trd)
	Util.tcheck(trd, "table")
	Util.tcheck(trd.type, "number")
	Util.tcheck(trd.tx, "number")
	Util.tcheck(trd.ty, "number")

	return TriggerInstantiator[trd.type](trd)
end

function init()
	assert(not data.__initialized)
	data.__initialized=true
end
