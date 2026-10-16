package time_converter

import "core:c"

SCALE::i64 = 1_000_000
MAX_TIME_MICRO::i64 = 1_000_000_000
MAX_INPUT_LENGTH::c.size_t = 4
INVALID_RESULT::f64 = -1.0e300

seconds_per_unit :: proc "contextless" (unit: i64) -> f64 {
	if unit == 0 do return 1.0
	if unit == 1 do return 60.0
	if unit == 2 do return 3600.0
	if unit == 3 do return 86400.0
	if unit == 4 do return 604800.0
	if unit == 5 do return 2629800.0
	if unit == 6 do return 31557600.0
	return 0.0
}

@(export)
time_converter :: proc "c" (values: [^]i64, length: c.size_t) -> f64 {
	if values == nil || length != 3 || length > MAX_INPUT_LENGTH do return INVALID_RESULT
	time_micro, from_unit, to_unit := values[0], values[1], values[2]
	if time_micro < 0 || time_micro > MAX_TIME_MICRO || from_unit < 0 || from_unit > 6 || to_unit < 0 || to_unit > 6 do return INVALID_RESULT
	time_value := f64(time_micro) / f64(SCALE)
	seconds_value := time_value * seconds_per_unit(from_unit)
	converted := seconds_value / seconds_per_unit(to_unit)
	rounded := i64(converted * 1000.0 + 0.5)
	return f64(rounded) / 1000.0
}
