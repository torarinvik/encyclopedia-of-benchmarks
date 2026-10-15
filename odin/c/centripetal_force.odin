package centripetal_force

import "core:c"

// Centripetal force: (mass * velocity^2) / radius.
@(export)
centripetal_force :: proc "c" (values: [^]i64, length: c.size_t) -> f64 {
	if values == nil || length != 3 do return -1.0e300
	mass := values[0]
	velocity := values[1]
	radius := values[2]
	if mass < 0 || mass > 1000 || velocity < -1000 || velocity > 1000 || radius < 1 || radius > 1000 do return -1.0e300
	velocity_squared := f64(velocity) * f64(velocity)
	return (f64(mass) * velocity_squared) / f64(radius)
}
