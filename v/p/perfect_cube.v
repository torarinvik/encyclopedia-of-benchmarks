module perfect_cube

// Test whether a signed value is an exact integer cube.
@[export: 'perfect_cube']
pub fn perfect_cube(value i64) i64 {
	if value < -1_000_000_000_000 || value > 1_000_000_000_000 { return -1 }
	target := u64(if value < 0 { -value } else { value })
	if target < 2 { return 1 }
	root_limit := if target <= 1000 { u64(10) } else if target <= 1000000 { u64(100) } else if target <= 1000000000 { u64(1000) } else { u64(10000) }
	half := target / 2
	mut low := u64(1)
	mut high := if half < root_limit { half } else { root_limit }
	for low <= high {
		middle := (low + high) >> 1
		cube := middle * middle * middle
		if cube == target { return 1 }
		if cube < target {
			if middle == high { return 0 }
			low = middle + 1
		} else {
			if middle == low { return 0 }
			high = middle - 1
		}
	}
	return 0
}
