module temperature_conversion

import math

const invalid_result = i64(-9223372036854775807 - 1)

fn convert_temperature(operation i64, value f64) f64 {
	match operation {
		0 { return (value * 9.0) / 5.0 + 32.0 }
		1 { return value + 273.15 }
		2 { return (value * 9.0) / 5.0 + 491.67 }
		3 { return ((value - 32.0) * 5.0) / 9.0 }
		4 { return ((value - 32.0) * 5.0) / 9.0 + 273.15 }
		5 { return value + 459.67 }
		6 { return value - 273.15 }
		7 { return ((value - 273.15) * 9.0) / 5.0 + 32.0 }
		8 { return (value * 9.0) / 5.0 }
		9 { return ((value - 491.67) * 5.0) / 9.0 }
		10 { return value - 459.67 }
		11 { return (value * 5.0) / 9.0 }
		12 { return value * 1.25 }
		13 { return value * 2.25 + 32.0 }
		14 { return value * 1.25 + 273.15 }
		else { return value * 2.25 + 32.0 + 459.67 }
	}
}

@[export: 'temperature_conversion']
pub fn temperature_conversion(values &i64, length usize) i64 {
	if length != 2 || unsafe { values == nil } { return invalid_result }
	unsafe {
		operation := values[0]
		temperature := values[1]
		if operation < 0 || operation > 15 || temperature < -1000000 || temperature > 1000000 { return invalid_result }
		return i64(math.floor(convert_temperature(operation, f64(temperature)) + 0.5))
	}
}
