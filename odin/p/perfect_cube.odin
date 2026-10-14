package perfect_cube

// Test whether a signed value is an exact integer cube.
@(export)
perfect_cube :: proc "c" (value: i64) -> i64 {
	if value < -1_000_000_000_000 || value > 1_000_000_000_000 do return -1
	target := abs(value)
	low: i64 = 0
	high: i64 = 10_000
	for low <= high {
		middle := low + (high - low) / 2
		cube := middle * middle * middle
		if cube == target do return 1
		if cube < target do low = middle + 1
		else do high = middle - 1
	}
	return 0
}
