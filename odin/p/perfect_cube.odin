package perfect_cube

// Test whether a signed value is an exact integer cube.
@(export)
perfect_cube :: proc "c" (value: i64) -> i64 {
	if value < -1_000_000_000_000 || value > 1_000_000_000_000 do return -1
	target := u64(abs(value))
	if target < 2 do return 1
	root_limit := u64(10) if target <= 1000 else u64(100) if target <= 1000000 else u64(1000) if target <= 1000000000 else u64(10000)
	low := u64(1)
	high := min(target / 2, root_limit)
	for low <= high {
		middle := (low + high) >> 1
		cube := middle * middle * middle
		if cube == target do return 1
		if cube < target {
			if middle == high do return 0
			low = middle + 1
		} else {
			if middle == low do return 0
			high = middle - 1
		}
	}
	return 0
}
