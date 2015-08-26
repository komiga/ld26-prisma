
module("Player", package.seeall)

require("src/Util")
require("src/Camera")

require("src/Data")

Dir = {
	Up = 1,
	Down = 2,
	Left = 3,
	Right = 4
}

-- Player interface

local data = {
	__initialized = false,
	x = nil,y = nil,
	rx = nil,ry = nil,
	color = nil,

	activation_queued = nil
}

function init(x, y, color)
	assert(not data.__initialized)

	Player.set_position(x, y)
	Player.reset(color)

	data.__initialized = true
end

function reset(color, hx, hy)
	Player.set_color(color)
	data.activation_queued = false
	if hx and hy then
		data.rx, data.ry = Data.tile_rpos(hx, hy)
	end
	Camera.set_position(data.rx + Data.HW, data.ry + Data.HH)
end

function update(dt)
	Camera.target(data.rx + Data.HW, data.ry + Data.HH)
end

function render(color_beneath)
	local line_color = Data.LineColorMatrix[data.color][color_beneath]
	Data.render_tile_abs(
		data.color, data.rx, data.ry,
		true, line_color
	)
end

function get_x()
	return data.x
end

function get_y()
	return data.y
end

function get_color()
	return data.color
end

function queue_activation()
	data.activation_queued = true
end

function remove_activation_queue()
	data.activation_queued = false
end

function has_activation_queued()
	return data.activation_queued
end

function set_color(color)
	data.color = color
end

function set_position(x, y)
	data.x = x
	data.y = y
	data.rx, data.ry = Data.tile_rpos(data.x, data.y)
end
