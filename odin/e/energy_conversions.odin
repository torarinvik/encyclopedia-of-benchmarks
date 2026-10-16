package energy_conversions

factor :: proc "contextless" (code: f64) -> f64 {
	if code == 0.0 do return 1.0
	if code == 1.0 do return 1000.0
	if code == 2.0 do return 1000000.0
	if code == 3.0 do return 1000000000.0
	if code == 4.0 do return 1.0
	if code == 5.0 do return 3600.0
	if code == 6.0 do return 3600000.0
	if code == 7.0 do return 1.0
	if code == 8.0 do return 4186.8
	if code == 9.0 do return 4186800.0
	if code == 10.0 do return 1.602176634e-19
	if code == 11.0 do return 1055.05585
	if code == 12.0 do return 1.355818
	return 0.0
}

@(export)
energy_conversions :: proc "c" (value, from_code, to_code: f64) -> f64 {
	if value != value || value < -1000000.0 || value > 1000000.0 do return -1e300
	source := factor(from_code)
	target := factor(to_code)
	if source == 0.0 || target == 0.0 do return -1e300
	scaled := value * source
	return scaled / target
}
