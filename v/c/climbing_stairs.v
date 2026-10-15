module climbing_stairs

// Count ways to climb n stairs using one or two steps per move.
@[export: 'climbing_stairs']
pub fn climbing_stairs(steps i64) i64 {
	if steps < 1 || steps > 45 { return -1 }
	mut previous := i64(1)
	mut current := i64(1)
	mut index := i64(2)
	for index <= steps {
		next := previous + current
		previous = current
		current = next
		index++
	}
	return current
}
