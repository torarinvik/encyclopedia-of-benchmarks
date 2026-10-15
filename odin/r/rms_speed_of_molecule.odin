package rms_speed_of_molecule

import "core:c"
import "core:math"

@(export)
rms_speed_of_molecule :: proc "c" (values: [^]i64, length: c.size_t) -> f64 {
	if values == nil || length != 2 do return -1.0e300
	temperature := values[0]
	molar_mass := values[1]
	if temperature < 0 || temperature > 1000 || molar_mass < 1 || molar_mass > 1000 do return -1.0e300
	numerator := (3.0 * 8.3144598) * f64(temperature)
	return math.pow(numerator / f64(molar_mass), 0.5)
}
