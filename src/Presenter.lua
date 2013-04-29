
module("Presenter", package.seeall)

require("src/Util")
require("src/FieldAnimator")
require("src/Bind")

local TransMode={
	Static=1,
	In=2,
	Out=3
}

local data={
	__initialized=false,
	font=nil,
	color={255,255,255},
	base_alpha=240,

	trans_in=nil,
	trans_out=nil,
	trans_mode=nil,

	active=nil,
	anim=nil,
	message=nil,
	hw=nil, hh=nil
}

function init(font)
	Util.tcheck_obj(font, "Font")
	assert(not data.__initialized)

	data.font=font

	data.trans_in={0, data.base_alpha}
	data.trans_out={data.base_alpha, 0}

	data.active=false
	data.trans_mode=TransMode.Static
	data.anim=FieldAnimator.new(
		0.25,
		{alpha=data.base_alpha},
		{["alpha"]=data.trans_in},
		FieldAnimator.Mode.Continue
	)
	data.message=""
	data.hw, data.hh=0.0, 0.0

	data.__initialized=true
end

function is_active()
	return data.active
end

function is_ending()
	return TransMode.Out==data.trans_mode
end

function update(dt)
	if data.active and TransMode.Static~=data.trans_mode then
		if data.anim:update(dt) then
			data.active=(TransMode.Out~=data.trans_mode)
			data.trans_mode=TransMode.Static
		end
	end
	return data.active
end

-- TODO: handle multiple lines (or just don't use them)
function render()
	if data.active then
		local alpha=Util.ternary(
			TransMode.Static==data.trans_mode,
			data.base_alpha, data.anim.fields.alpha
		)
		local x=Core.display_width_half -data.hw
		local y=Core.display_height_half-data.hh

		-- TODO: needs more weight
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

function start(message, fade_in)
	Util.debug("Presenter.start()")
	data.active=true
	data.trans_mode=TransMode.Static
	data.message=message

	data.hw=0.5*data.font:getWidth(data.message)
	data.hh=0.5*data.font:getHeight(data.message)

	if fade_in then
		data.trans_mode=TransMode.In
		data.anim.trans["alpha"]=data.trans_in
		data.anim:reset()
	end
end

function stop()
	Util.debug("Presenter.stop()")
	if data.active and not Presenter.is_ending() then
		data.trans_mode=TransMode.Out
		data.anim.trans["alpha"]=data.trans_out
		data.anim:reset()
	end
end
