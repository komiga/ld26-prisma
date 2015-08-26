
module("Camera", package.seeall)

require("src/Util")
require("src/AudioManager")

data = data or {
	__love_translate = Gfx.translate,
	__initialized = false,
	cam = nil
}

data.__camera_translate = function(x, y)
	data.__love_translate(
		Core.display_width_half - data.cam.x + x,
		Core.display_height_half - data.cam.y + y
	)
end

-- class Camera

local Unit = {}
Unit.__index = Unit

function Unit:__init(x, y, speed)
	Util.tcheck(x, "number")
	Util.tcheck(y, "number")
	Util.tcheck(speed, "number", true)

	speed = Util.optional(speed, 0)

	self.x = x
	self.y = y
	self.speed = speed
	self.time = 0
	self.distance = 0
	self.x_origin = 0
	self.y_origin = 0
	self.x_target = 0
	self.y_target = 0
	self.x_speed = 0
	self.y_speed = 0
	self.locked = false
end

function Unit:set_position(x, y)
	self.distance = 0
	self.x = x
	self.y = y
end

function Unit:target(x, y)
	if 0 == self.speed then
		self.x = x
		self.y = y
	elseif x ~= self.x or y ~= self.y then
		local rx = x - self.x
		local ry = y - self.y
		self.time = 0
		self.distance = math.sqrt((rx * rx) + (ry * ry))
		self.x_origin = self.x
		self.y_origin = self.y
		self.x_target = x
		self.y_target = y
		self.x_speed = rx / self.distance
		self.y_speed = ry / self.distance
	end
end

function Unit:move(x, y)
	self:target(self.x + x, self.y + y)
end

function Unit:update(dt)
	if 0 ~= self.distance then
		self.time = self.time + dt
		local travelled = self.time * self.speed
		if travelled >= self.distance then
			self.distance = 0
			self.x = self.x_target
			self.y = self.y_target
		else
			self.x = self.x_origin + travelled * self.x_speed
			self.y = self.y_origin + travelled * self.y_speed
		end
	end
end

function Unit:lock()
	assert(not self.locked)
	Gfx.push()
	Gfx.translate = data.__camera_translate
	Gfx.translate(0, 0)
	self.locked = true
end

function Unit:unlock()
	assert(self.locked)
	Gfx.translate = data.__love_translate
	Gfx.pop()
	self.locked = false
end

-- Camera interface

-- If speed is 0, :move() and :target()
-- are the same as :set_position()
function new(x, y, speed)
	return Util.new_object(Unit, x, y, speed)
end

function init(x, y, speed)
	assert(not data.__initialized)

	data.cam = Camera.new(x, y, speed)

	data.__initialized = true
	return data.cam
end

function srel_x(x)
	return data.cam.x - Core.display_width_half + x
end

function srel_y(y)
	return data.cam.y - Core.display_height_half + y
end

function rel_x(x)
	return x + data.cam.x
end

function rel_y(y)
	return y + data.cam.y
end

function srel(x, y)
	return rel_x(x), rel_y(y)
end

function rel(x, y)
	return rel_x(x), rel_y(y)
end

function get()
	return data.cam
end

function set(cam)
	data.cam = cam
end

function set_position(x, y)
	data.cam:set_position(x, y)
end

function target(x, y)
	data.cam:target(x, y)
end

function move(x, y)
	data.cam:move(x, y)
end

function update(dt)
	AudioManager.set_position(data.cam.x, data.cam.y)
	data.cam:update(dt)
end

function lock()
	data.cam:lock()
end

function unlock()
	data.cam:unlock()
end
