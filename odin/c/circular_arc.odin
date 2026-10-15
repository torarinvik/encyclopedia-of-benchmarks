package circular_arc

import "core:c"

@(export)
circular_arc :: proc "c" (input: [^]i64, length: c.size_t) -> f64 {
	if input == nil || length != 3 do return -1.0e300
	mode, radius, degrees := input[0], input[1], input[2]
	if (mode != 0 && mode != 1) || radius < -1_000_000 || radius > 1_000_000 || degrees < -360_000 || degrees > 360_000 do return -1.0e300
	angle := f64(degrees) * (3.14159265358979323846 / 180.0)
	if mode == 0 do return f64(radius) * angle
	return f64(radius * radius) * angle / 2.0
}
