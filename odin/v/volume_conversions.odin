package volume_conversions

import "core:c"

unit_factor_to_cubic_meters :: proc "contextless" (unit: i64) -> f64 {
	if unit == 1 do return 0.001
	return 1.0
}

put_f64_le :: proc "contextless" (value: f64, output: [^]u8) {
	bits := transmute(u64)value
	for byte := 0; byte < 8; byte += 1 {
		output[byte] = u8(bits >> u64(8 * byte))
	}
}

@(export)
volume_conversions :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length != 3 do return -1
	value, from_unit, to_unit := input[0], input[1], input[2]
	if value < 0 || value > 1000 || from_unit < 0 || from_unit > 2 || to_unit < 0 || to_unit > 2 || from_unit == to_unit do return -1
	if capacity < 8 || output == nil do return -2
	cubic_meters := f64(value) * unit_factor_to_cubic_meters(from_unit)
	converted := cubic_meters / unit_factor_to_cubic_meters(to_unit)
	put_f64_le(converted, output)
	return 8
}
