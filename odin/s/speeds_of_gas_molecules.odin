package speeds_of_gas_molecules

import "core:c"
import "core:math"

MAX_INPUT_LENGTH :: 4
MAX_TEMPERATURE_MK :: i64(1_000_000)
MAX_MOLAR_MASS_MICRO :: i64(1_000_000_000)
GAS_CONSTANT :: 8.31446261815324
PI_VALUE :: 3.14159265358979323846264338327950288
INVALID_RESULT :: -1.0e300

@(export)
speeds_of_gas_molecules :: proc "c" (input: [^]i64, length: c.size_t) -> f64 {
	if input == nil || length < 3 || length > MAX_INPUT_LENGTH do return INVALID_RESULT
	operation := input[0]
	temperature_mk := input[1]
	molar_mass_micro := input[2]
	if length != 3 || operation < 0 || operation > 1 ||
		temperature_mk < 0 || temperature_mk > MAX_TEMPERATURE_MK ||
		molar_mass_micro < 1 || molar_mass_micro > MAX_MOLAR_MASS_MICRO do return INVALID_RESULT

	temperature := f64(temperature_mk) / 1000.0
	molar_mass := f64(molar_mass_micro) / 1_000_000.0
	if operation == 0 do return math.pow_f64((8.0 * GAS_CONSTANT * temperature) / (PI_VALUE * molar_mass), 0.5)
	return math.pow_f64((2.0 * GAS_CONSTANT * temperature) / molar_mass, 0.5)
}
