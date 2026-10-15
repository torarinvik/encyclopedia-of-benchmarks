package relativistic_kinetic_energy

import "core:c"
import "core:math"

SPEED_OF_LIGHT :: i64(299792458)
INVALID_RESULT :: -1.0e300

@(export)
relativistic_kinetic_energy :: proc "c" (values: [^]i64, length: c.size_t) -> f64 {
	if values == nil || length != 2 do return INVALID_RESULT
	mass := values[0]
	velocity := values[1]
	if mass < 0 || mass > 1_000_000 || velocity < -(SPEED_OF_LIGHT-1) || velocity > SPEED_OF_LIGHT-1 do return INVALID_RESULT
	c_squared := SPEED_OF_LIGHT * SPEED_OF_LIGHT
	gamma := 1.0 / math.sqrt_f64(1.0 - f64(velocity*velocity)/f64(c_squared))
	return (gamma - 1.0) * f64(mass) * f64(c_squared)
}
