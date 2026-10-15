package climbing_stairs

// Count ways to climb n stairs using one or two steps per move.
@(export)
climbing_stairs :: proc "c" (steps: i64) -> i64 {
	if steps < 1 || steps > 45 do return -1
	previous := i64(1)
	current := i64(1)
	for index := i64(2); index <= steps; index += 1 {
		next := previous + current
		previous = current
		current = next
	}
	return current
}
