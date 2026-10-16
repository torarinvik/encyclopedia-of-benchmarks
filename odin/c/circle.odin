package circle

INVALID_RESULT :: -1.0e300
PI :: 3.14159265358979323846

@(export)
circle :: proc "c" (radius, operation: f64) -> f64 {
	if !(radius >= -1_000_000 && radius <= 1_000_000 && (operation == 0 || operation == 1)) do return INVALID_RESULT
	if operation == 0 do return radius * 2 * PI
	return radius * radius * PI
}
