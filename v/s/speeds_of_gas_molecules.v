module speeds_of_gas_molecules

import math

const max_input_length = usize(4)
const max_temperature_mk = i64(1_000_000)
const max_molar_mass_micro = i64(1_000_000_000)
const gas_constant = 8.31446261815324
const pi_value = 3.14159265358979323846264338327950288
const invalid_result = -1.0e300

@[export: 'speeds_of_gas_molecules']
pub fn speeds_of_gas_molecules(input &i64, length usize) f64 {
	if unsafe { input == nil } || length < 3 || length > max_input_length { return invalid_result }
	unsafe {
		operation := input[0]
		temperature_mk := input[1]
		molar_mass_micro := input[2]
		if length != 3 || operation < 0 || operation > 1 ||
			temperature_mk < 0 || temperature_mk > max_temperature_mk ||
			molar_mass_micro < 1 || molar_mass_micro > max_molar_mass_micro { return invalid_result }

		temperature := f64(temperature_mk) / 1000.0
		molar_mass := f64(molar_mass_micro) / 1_000_000.0
		if operation == 0 { return math.pow((8.0 * gas_constant * temperature) / (pi_value * molar_mass), 0.5) }
		return math.pow((2.0 * gas_constant * temperature) / molar_mass, 0.5)
	}
}
