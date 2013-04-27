
module("Player", package.seeall)

require("src/Util")
require("src/Camera")

require("src/Data")
require("src/Sentient")

-- Player interface

local data={
	__initialized=false,
	sentient=nil,
	tris=nil,
	rx=nil,ry=nil
}

function init(x, y, color)
	assert(not data.__initialized)

	data.sentient=Sentient.new(x, y, color)
	data.tris={}
	set_position(x, y)

	data.__initialized=true
end

function reset(color)
	data.sentient:reset(data.sentient.x, data.sentient.y, color)
	data.tris={}
end

function update(dt)
	data.sentient:update(dt)
	Camera.target(data.rx+Data.HW, data.ry+Data.HH)
end

function render(beneath)
	data.sentient:render(true)
end

function get_x()
	return data.sentient.x
end

function get_y()
	return data.sentient.y
end

function get_color()
	return data.sentient.color
end

function get_sentient()
	return data.sentient
end

function set_position(x, y)
	data.sentient.x=x
	data.sentient.y=y
	data.rx, data.ry=Data.tile_rpos(data.sentient.x, data.sentient.y)
end
