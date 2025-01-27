local catppuccin = {
  rosewater = 0xFFF5E0DC,
  flamingo = 0xFFF2CDCD,
  pink = 0xFFF5C2E7,
  mauve = 0xFFCBA6F7,
  red = 0xFFF38BA8,
  maroon = 0xFFEBA0AC,
  peach = 0xFFFAB387,
  yellow = 0xFFF9E2AF,
  green = 0xFFA6E3A1,
  teal = 0xFF94E2D5,
  sky = 0xFF89DCEB,
  sapphire = 0xFF74C7EC,
  blue = 0xFF89B4FA,
  lavender = 0xFFB4BFEF,
  text = 0xFFCDD6F4,
  subtext1 = 0xFFBAC2DE,
  subtext0 = 0xFFA6ADC8,
  overlay2 = 0xFF9399B2,
  overlay1 = 0xFF7F849C,
  overlay0 = 0xFF6C7086,
  surface2 = 0xFF585B70,
  surface1 = 0xFF45475A,
  surface0 = 0xFF313244,
  base = 0xFF1E1E2E,
  mantle = 0xFF181825,
  crust = 0xFF11111B,
  white = 0xFFFFFFFF,
}

return {
	black = catppuccin.base,
	white = catppuccin.white,
	red = catppuccin.red,
	green = catppuccin.green,
	blue = catppuccin.blue,
	yellow = catppuccin.yellow,
	orange = catppuccin.orange,
	magenta = catppuccin.mauve,
	grey = catppuccin.overlay0,
	teal = catppuccin.teal,
	transparent = 0x00000000,

	bar = {
		bg = catppuccin.crust,
		border = catppuccin.surface0,
	},
	popup = {
		bg = catppuccin.base,
		border = catppuccin.overlay0,
		card = catppuccin.base,
	},
	spaces = {
		active = catppuccin.surface1,
		inactive = catppuccin.surface0,
	},
	bg1 = catppuccin.surface1,
	bg2 = catppuccin.surface2,

	with_alpha = function(color, alpha)
		if alpha > 1.0 or alpha < 0.0 then
			return color
		end
		return (color & 0x00ffffff) | (math.floor(alpha * 255.0) << 24)
	end,
}
