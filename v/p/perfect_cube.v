module perfect_cube

// Test whether a signed value is an exact integer cube.
@[export: 'perfect_cube']
pub fn perfect_cube(value i64) i64 {
	if value < -1_000_000_000_000 || value > 1_000_000_000_000 { return -1 }
	target := if value < 0 { -value } else { value }
	mut low := i64(0)
	mut high := i64(10_000)
	for low <= high {
		middle := low + (high - low) / 2
		cube := middle * middle * middle
		if cube == target { return 1 }
		if cube < target { low = middle + 1 } else { high = middle - 1 }
	}
	return 0
}
