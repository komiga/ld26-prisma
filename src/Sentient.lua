
module("Sentient", package.seeall)

require("src/Util")

require("src/Data")

local Unit={}
Unit.__index=Unit

-- NOTE: x and y are tile coords

function Unit:__init(x, y, color)
	Util.tcheck(x, "number")
	Util.tcheck(y, "number")
	Util.tcheck(color, "number")

	self:reset(x, y, color)
end

function Unit:reset(x, y, color)
	self.x=x
	self.y=y
	self.color=color
end

function Unit:update(dt)
end

function Unit:render(lined)
	Data.render_tile(self.color, self.x, self.y, lined)
end

function new(x, y, color)
	return Util.new_object(Unit, x, y, color)
end

-- class Bucket

local Bucket={}
Bucket.__index=Bucket

function Bucket:__init()
	self.active={}
	self.free={}
end

function Bucket:clear()
	for _, snt in pairs(self.active) do
		table.insert(self.free, snt)
	end
	self.active={}
end

function Bucket:get_sentient(idx)
	assert(#self.active>=idx)
	local snt=self.active[idx]
	assert(nil~=snt)
	return snt
end

function Bucket:spawn(x, y, color)
	color=Util.optional(color, Data.Color.Red)
	local snt=nil
	if 0<#self.free then
		snt=Util.last(self.free)
		table.remove(self.free)
		snt:reset(x, y, color)
	else
		snt=Util.new_object(Unit, x, y, color)
	end
	table.insert(self.active, snt)
	return #self.active
end

function Bucket:update(dt)
	for _, snt in pairs(self.active) do
		snt:update(dt)
	end
end

-- TODO: take world data, render based on tile beneath
function Bucket:render()
	for _, snt in pairs(self.active) do
		snt:render(false)
	end
end

-- Sentient interface

local data={
	__initialized=false
}

function init()
	assert(not data.__initialized)
	data.__initialized=true
end

function new_bucket()
	return Util.new_object(Bucket)
end
