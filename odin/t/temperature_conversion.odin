package temperature_conversion

import "core:c"
import "core:math"

INVALID_RESULT :: i64(-9223372036854775807 - 1)

convert_temperature :: proc(operation: i64, value: f64) -> f64 {
	switch operation {
	case 0: return (value * 9.0) / 5.0 + 32.0
	case 1: return value + 273.15
	case 2: return (value * 9.0) / 5.0 + 491.67
	case 3: return ((value - 32.0) * 5.0) / 9.0
	case 4: return ((value - 32.0) * 5.0) / 9.0 + 273.15
	case 5: return value + 459.67
	case 6: return value - 273.15
	case 7: return ((value - 273.15) * 9.0) / 5.0 + 32.0
	case 8: return (value * 9.0) / 5.0
	case 9: return ((value - 491.67) * 5.0) / 9.0
	case 10: return value - 459.67
	case 11: return (value * 5.0) / 9.0
	case 12: return value * 1.25
	case 13: return value * 2.25 + 32.0
	case 14: return value * 1.25 + 273.15
	case: return value * 2.25 + 32.0 + 459.67
	}
}

@(export)
temperature_conversion :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if values == nil || length != 2 do return INVALID_RESULT
	operation := values[0]
	temperature := values[1]
	if operation < 0 || operation > 15 || temperature < -1000000 || temperature > 1000000 do return INVALID_RESULT
	return i64(math.floor(convert_temperature(operation, f64(temperature)) + 0.5))
}
