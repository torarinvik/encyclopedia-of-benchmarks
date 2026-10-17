package temparature_conversion

import "core:c"
import "core:math"

MAX_ABS_TEMPERATURE_MICRO :: i64(1_000_000_000_000)
MAX_INPUT_LENGTH :: c.size_t(4)
INVALID_RESULT :: f64(-1e300)

round_nearest_ties_even :: proc "contextless" (value: f64) -> f64 {
	lower := math.floor_f64(value)
	fraction := value - lower
	if fraction < 0.5 do return lower
	if fraction > 0.5 do return lower + 1.0
	integer := i64(lower)
	if integer % 2 == 0 do return lower
	return lower + 1.0
}

round_digits :: proc "contextless" (value: f64, digits: i64) -> f64 {
	scale := f64(1)
	magnitude := digits
	if magnitude < 0 do magnitude = -magnitude
	for index := i64(0); index < magnitude; index += 1 {
		scale *= 10.0
	}
	scaled := value * scale
	if digits < 0 do scaled = value / scale
	rounded := round_nearest_ties_even(scaled)
	if digits >= 0 do return rounded / scale
	return rounded * scale
}

@(export)
temparature_conversion :: proc "c" (input: [^]i64, length: c.size_t) -> f64 {
	if input == nil || length < 3 || length > MAX_INPUT_LENGTH do return INVALID_RESULT
	operation, temperature_micro, digits := input[0], input[1], input[2]
	if length != 3 || operation < 0 || operation > 5
		|| temperature_micro < -MAX_ABS_TEMPERATURE_MICRO || temperature_micro > MAX_ABS_TEMPERATURE_MICRO
		|| digits < -6 || digits > 6 do return INVALID_RESULT

	temperature := f64(temperature_micro) / 1_000_000.0
	result := f64(0)
	switch operation {
	case 0: result = temperature * 1.8 + 32.0
	case 1: result = temperature + 273.15
	case 2: result = (temperature - 32.0) * 5.0 / 9.0
	case 3: result = (temperature - 32.0) * 5.0 / 9.0 + 273.15
	case 4: result = temperature - 273.15
	case 5: result = (temperature - 273.15) * 1.8 + 32.0
	}
	return round_digits(result, digits)
}
