package hookes_law

import "core:c"

@(export)
hookes_law :: proc "c" (values: [^]i64, length: c.size_t) -> f64 {
	if values == nil || length != 2 do return -1.0e300
	spring_constant := values[0]
	displacement := values[1]
	if spring_constant < 1 || spring_constant > 1000 || displacement < -1000 || displacement > 1000 do return -1.0e300
	return (-f64(spring_constant)) * f64(displacement)
}
