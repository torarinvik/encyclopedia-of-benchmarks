package weight_conversion

destination_factor :: proc "contextless" (code: f64) -> f64 {
	if code == 0.0 do return 1.0
	if code == 1.0 do return 1000.0
	if code == 2.0 do return 1000000.0
	if code == 3.0 do return 0.001
	if code == 4.0 do return 0.0009842073
	if code == 5.0 do return 0.0011023122
	if code == 6.0 do return 2.2046244202
	if code == 7.0 do return 0.1574731728
	if code == 8.0 do return 35.273990723
	if code == 9.0 do return 5000.0
	if code == 10.0 do return 6.022136652e26
	return 0.0
}

source_factor :: proc "contextless" (code: f64) -> f64 {
	if code == 0.0 do return 1.0
	if code == 1.0 do return 0.001
	if code == 2.0 do return 0.000001
	if code == 3.0 do return 1000.0
	if code == 4.0 do return 1016.04608
	if code == 5.0 do return 907.184
	if code == 6.0 do return 0.453592
	if code == 7.0 do return 6.35029
	if code == 8.0 do return 0.0283495
	if code == 9.0 do return 0.0002
	if code == 10.0 do return 1.660540199e-27
	return 0.0
}

@(export)
weight_conversion :: proc "c" (value, from_code, to_code: f64) -> f64 {
	if value != value || value < -1000000.0 || value > 1000000.0 do return -1e300
	destination := destination_factor(to_code)
	source := source_factor(from_code)
	if destination == 0.0 || source == 0.0 do return -1e300
	scaled := value * destination
	return scaled * source
}
