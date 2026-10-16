package temperature_converter

import "core:c"

MAX_ABS_TEMPERATURE_MICRO::i64 = 1_000_000_000_000
MAX_INPUT_LENGTH::c.size_t = 3
INVALID_RESULT::f64 = -1e300

@(export)
temperature_converter :: proc "c" (values: [^]i64, length: c.size_t) -> f64 {
	if values == nil || length != 2 || length > MAX_INPUT_LENGTH do return INVALID_RESULT
	operation, temperature_micro := values[0], values[1]
	if temperature_micro < -MAX_ABS_TEMPERATURE_MICRO || temperature_micro > MAX_ABS_TEMPERATURE_MICRO do return INVALID_RESULT
	temperature := f64(temperature_micro) / 1_000_000.0
	switch operation {
	case 0: return temperature * 9.0 / 5.0 + 32.0
	case 1: return temperature + 273.15
	case 2: return (temperature - 32.0) * 5.0 / 9.0
	case 3: return (temperature - 32.0) * 5.0 / 9.0 + 273.15
	case 4: return temperature - 273.15
	case 5: return (temperature - 273.15) * 9.0 / 5.0 + 32.0
	}
	return INVALID_RESULT
}
