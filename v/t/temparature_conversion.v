module temparature_conversion

import math

const max_abs_temperature_micro = i64(1_000_000_000_000)
const max_input_length = usize(4)
const invalid_result = -1.0e300

fn round_nearest_ties_even(value f64) f64 {
	lower := math.floor(value)
	fraction := value - lower
	if fraction < 0.5 { return lower }
	if fraction > 0.5 { return lower + 1.0 }
	integer := i64(lower)
	return if integer % 2 == 0 { lower } else { lower + 1.0 }
}

fn round_digits(value f64, digits i64) f64 {
	mut scale := 1.0
	magnitude := if digits < 0 { -digits } else { digits }
	for _ in 0 .. int(magnitude) { scale *= 10.0 }
	scaled := if digits >= 0 { value * scale } else { value / scale }
	rounded := round_nearest_ties_even(scaled)
	return if digits >= 0 { rounded / scale } else { rounded * scale }
}

@[export: 'temparature_conversion']
pub fn temparature_conversion(input &i64, length usize) f64 {
	if unsafe { input == nil } || length < 3 || length > max_input_length { return invalid_result }
	unsafe {
		operation, temperature_micro, digits := input[0], input[1], input[2]
		if length != 3 || operation < 0 || operation > 5
			|| temperature_micro < -max_abs_temperature_micro || temperature_micro > max_abs_temperature_micro
			|| digits < -6 || digits > 6 { return invalid_result }

		temperature := f64(temperature_micro) / 1_000_000.0
		result := match operation {
			0 { temperature * 1.8 + 32.0 }
			1 { temperature + 273.15 }
			2 { (temperature - 32.0) * 5.0 / 9.0 }
			3 { (temperature - 32.0) * 5.0 / 9.0 + 273.15 }
			4 { temperature - 273.15 }
			5 { (temperature - 273.15) * 1.8 + 32.0 }
			else { return invalid_result }
		}
		return round_digits(result, digits)
	}
}
