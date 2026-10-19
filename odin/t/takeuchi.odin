package takeuchi

MAX_INPUT :: 12

tak :: proc "contextless" (x, y, z: i64) -> i64 {
	if y < x {
		return tak(tak(x - 1, y, z), tak(y - 1, z, x), tak(z - 1, x, y))
	}
	return z
}

@(export)
takeuchi :: proc "c" (x, y, z: i64) -> i64 {
	if x < 0 || x > MAX_INPUT || y < 0 || y > MAX_INPUT || z < 0 || z > MAX_INPUT do return -1
	return tak(x, y, z)
}
