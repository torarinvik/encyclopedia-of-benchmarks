package potential_energy

import "core:c"

// Gravitational potential energy: mass * standard gravity * height.
@(export)
potential_energy :: proc "c" (values: [^]i64, length: c.size_t) -> f64 {
	if values == nil || length != 2 do return -1.0e300
	mass := values[0]
	height := values[1]
	if mass < 0 || mass > 1000 || height < 0 || height > 1000 do return -1.0e300
	return (f64(mass) * 9.80665) * f64(height)
}
