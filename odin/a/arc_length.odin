package arc_length

PI :: 3.141592653589793238462643383279502884

// Return arc length; unit 0 uses degrees and unit 1 uses radians.
@(export)
arc_length :: proc "c" (radius, angle, unit: f64) -> f64 {
	if unit == 0 do return 2.0 * PI * radius * (angle / 360.0)
	return radius * angle
}
