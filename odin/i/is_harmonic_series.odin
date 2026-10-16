package is_harmonic_series

import "core:c"

MAX_VALUES :: 32
INVALID_RESULT :: -1.0e300

@(export)
is_harmonic_series :: proc "c" (values: [^]i64, length: c.size_t) -> f64 {
	if values == nil || length < 2 || length > MAX_VALUES + 1 do return INVALID_RESULT
	count := values[0]
	if count < 1 || count > MAX_VALUES || length != c.size_t(count + 1) do return INVALID_RESULT
	var reciprocals: [MAX_VALUES]f64
	for i := 0; i < int(count); i += 1 {
		value := transmute(f64) values[i + 1]
		if value == 0.0 do return INVALID_RESULT
		reciprocals[i] = 1.0 / value
	}
	if count == 1 do return 1.0
	common_difference := reciprocals[1] - reciprocals[0]
	for i := 2; i < int(count); i += 1 {
		if reciprocals[i] - reciprocals[i - 1] != common_difference do return 0.0
	}
	return 1.0
}
