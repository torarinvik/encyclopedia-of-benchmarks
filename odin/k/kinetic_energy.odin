package kinetic_energy

import "core:c"

// Classical kinetic energy: 0.5 * mass * abs(velocity)^2.
@(export)
kinetic_energy :: proc "c" (values: [^]i64, length: c.size_t) -> f64 {
	if values == nil || length != 2 do return -1.0e300
	mass := values[0]
	velocity := values[1]
	if mass < 0 || mass > 1000 || velocity < -1000 || velocity > 1000 do return -1.0e300
	speed := velocity
	if speed < 0 do speed = -speed
	return ((0.5 * f64(mass)) * f64(speed)) * f64(speed)
}
