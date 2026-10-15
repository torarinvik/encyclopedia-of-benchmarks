package reynolds_number

import "core:c"

@(export)
reynolds_number :: proc "c" (values: [^]i64, length: c.size_t) -> f64 {
	if values == nil || length != 4 do return -1.0e300
	density := values[0]
	velocity := values[1]
	diameter := values[2]
	viscosity := values[3]
	if density < 1 || density > 1000 || velocity < -1000 || velocity > 1000 || diameter < 1 || diameter > 1000 || viscosity < 1 || viscosity > 1000 do return -1.0e300
	speed := velocity
	if speed < 0 do speed = -speed
	return (((f64(density) * f64(speed)) * f64(diameter)) / f64(viscosity))
}
