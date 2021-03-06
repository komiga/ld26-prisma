
module("FieldAnimator", package.seeall)

require("src/Util")

Mode = {
	Stop = 1,
	Wrap = 2,
	Continue = 3
}

-- class FieldAnimator

local Unit = {}
Unit.__index = Unit

function Unit:__init(duration, fields, trans, mode, serial_reset_callback)
	Util.tcheck(duration, "number")
	Util.tcheck(fields, "table")
	Util.tcheck(trans, "table")
	Util.tcheck(mode, "number", true)
	Util.tcheck(serial_reset_callback, "function", true)

	self.duration = duration
	self.fields = fields
	self.trans = trans
	self.mode = Util.optional(mode, Mode.Stop)
	self.serial_reset_callback = serial_reset_callback
	self:reset()
end

function Unit:is_complete()
	return 1.0 <= self.total
end

function Unit:reset()
	self.time = 0.0
	self.total = 0.0
	self.picked = {}
	for f, t in pairs(self.trans) do
		if "table" == type(t[1]) then
			-- trans for field is a table of variants
			-- instead of a direct (base,target) pair
			local index = Util.random(1, #t)
			self.picked[f] = index
		end
		local value = self:get_field_trans(f)[1]
		if "table" == type(f) then
			for _, af in pairs(f) do
				self:__post(af, value)
			end
		else
			self:__post(f, value)
		end
	end
end

function Unit:get_field_trans(f)
	local index = self.picked[f]
	if nil ~= index then
		return self.trans[f][index]
	else
		return self.trans[f]
	end
end

function Unit:__post(f, value)
	if "function" == type(self.fields[f]) then
		self.fields[f](value, self)
	else
		self.fields[f] = value
	end
end

function Unit:__update_field_table(f, t)
	local value = t[1] + ((t[2] - t[1]) * self.total)
	for _, af in pairs(f) do
		self:__post(af, value)
	end
end

function Unit:__update_field(f, t)
	local value = t[1] + ((t[2] - t[1]) * self.total)
	self:__post(f, value)
end

function Unit:update(dt)
	self.time = self.time + dt
	if Mode.Continue ~= self.mode and self.time >= self.duration then
		if Mode.Stop == self.mode then
			self.time = self.duration
			self.total = 1.0
			if self.serial_reset_callback then
				self.serial_reset_callback(self)
			end
		elseif Mode.Wrap == self.mode then
			self:reset()
			if self.serial_reset_callback then
				self.serial_reset_callback(self)
			end
		end
	else
		self.total = self.time / self.duration
	end
	for f, _ in pairs(self.trans) do
		if "table" == type(f) then
			self:__update_field_table(f, self:get_field_trans(f))
		else
			self:__update_field(f, self:get_field_trans(f))
		end
	end
	return self:is_complete()
end

-- FieldAnimator interface

function new(duration, fields, trans, mode, serial_reset_callback)
	return Util.new_object(
		Unit,
		duration, fields, trans, mode, serial_reset_callback
	)
end
