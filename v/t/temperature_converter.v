module temperature_converter

const max_abs_temperature_micro = i64(1_000_000_000_000)
const max_input_length = usize(3)
const invalid_result = -1.0e300

@[export: 'temperature_converter']
pub fn temperature_converter(values &i64, length usize) f64 {
	if length != 2 || length > max_input_length || unsafe { values == nil } { return invalid_result }
	operation, temperature_micro := unsafe { values[0] }, unsafe { values[1] }
	if temperature_micro < -max_abs_temperature_micro || temperature_micro > max_abs_temperature_micro { return invalid_result }
	temperature := f64(temperature_micro) / 1_000_000.0
	return match operation {
		0 { temperature * 9.0 / 5.0 + 32.0 }
		1 { temperature + 273.15 }
		2 { (temperature - 32.0) * 5.0 / 9.0 }
		3 { (temperature - 32.0) * 5.0 / 9.0 + 273.15 }
		4 { temperature - 273.15 }
		5 { (temperature - 273.15) * 9.0 / 5.0 + 32.0 }
		else { invalid_result }
	}
}
