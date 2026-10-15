module trapped_rainwater

// Sum trapped water using per-position prefix and suffix maxima.
@[export: 'trapped_rainwater']
pub fn trapped_rainwater(heights &i64, length usize) i64 {
	if length > 4096 { return -1 }
	for index in 0 .. length {
		value := unsafe { heights[index] }
		if value < 0 || value > 1000000 { return -1 }
	}
	if length < 3 { return 0 }

	mut left_max := [4096]i64{}
	mut right_max := [4096]i64{}
	left_max[0] = unsafe { heights[0] }
	for index in 1 .. length {
		value := unsafe { heights[index] }
		left_max[index] = if left_max[index - 1] > value { left_max[index - 1] } else { value }
	}
	last := length - 1
	right_max[last] = unsafe { heights[last] }
	mut index := last
	for index > 0 {
		index--
		value := unsafe { heights[index] }
		right_max[index] = if right_max[index + 1] > value { right_max[index + 1] } else { value }
	}

	mut water := i64(0)
	for position in 0 .. length {
		boundary := if left_max[position] < right_max[position] { left_max[position] } else { right_max[position] }
		water += boundary - unsafe { heights[position] }
	}
	return water
}
