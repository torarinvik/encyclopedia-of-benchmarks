package mass_energy_equivalence

import "core:c"

SPEED_OF_LIGHT :: 299792458.0
SPEED_OF_LIGHT_SQUARED :: SPEED_OF_LIGHT * SPEED_OF_LIGHT

@(export)
mass_energy_equivalence :: proc "c" (values: [^]i64, length: c.size_t) -> f64 {
	if values == nil || length != 2 do return -1.0e300
	operation, value := values[0], values[1]
	if (operation != 0 && operation != 1) || value < 0 || value > 1000000000 do return -1.0e300
	if operation == 0 do return f64(value) * SPEED_OF_LIGHT_SQUARED
	return f64(value) / SPEED_OF_LIGHT_SQUARED
}
