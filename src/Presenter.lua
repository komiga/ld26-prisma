
module("Presenter", package.seeall)

require("src/Util")
require("src/FieldAnimator")
require("src/Bind")

local data={
	__initialized=false,
	font=nil,
	color={255,255,255},
	base_alpha=240,

	active=nil,
	ending=nil,
	anim=nil,
	message=nil,
	hw=nil, hh=nil
}

function init(font)
	Util.tcheck_obj(font, "Font")
	assert(not data.__initialized)

	data.font=font

	data.active=false
	data.ending=false
	data.anim=FieldAnimator.new(
		0.25,
		{alpha=data.base_alpha},
		{["alpha"]={data.base_alpha, 0}},
		FieldAnimator.Mode.Continue
	)
	data.message="blblbl"
	data.hw, data.hh=0.0, 0.0

	data.__initialized=true
end

function is_active()
	return data.active
end

function is_ending()
	return data.ending
end

function update(dt)
	if data.active and data.ending then
		if data.anim:update(dt) then
			data.active=false
			data.ending=false
		end
	end
	return data.active
end

-- TODO: handle multiple lines (or just don't use them)
function render()
	if data.active then
		local alpha=Util.ternary(
			data.ending,
			data.anim.fields.alpha, data.base_alpha
		)
		local x=Core.display_width_half -data.hw
		local y=Core.display_height_half-data.hh

		-- TODO: banner needs more weight
		Gfx.setColor(0,0,0, alpha)
		Gfx.rectangle("fill",
			--0.0, y-(0.5*Core.display_height_half)+data.hh,
			--Core.display_width, Core.display_height_half
			0.0, 0.0,
			Core.display_width, Core.display_height
		)

		Util.set_color_table(data.color, alpha+10)
		Gfx.setFont(data.font)
		Gfx.print(data.message, x, y)
	end
end

function start(message)
	Util.debug("Presenter.start()")
	data.active=true
	data.ending=false
	data.message=message

	data.hw=0.5*data.font:getWidth(data.message)
	data.hh=0.5*data.font:getHeight(data.message)
end

function stop()
	Util.debug("Presenter.stop()")
	if data.active and not data.ending then
		data.ending=true
		data.anim:reset()
	end
end
