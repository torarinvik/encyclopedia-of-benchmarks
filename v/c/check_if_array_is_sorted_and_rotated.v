module check_if_array_is_sorted_and_rotated

// Check whether the values are a rotation of a nondecreasing array.
@[export: 'check_if_array_is_sorted_and_rotated']
pub fn check_if_array_is_sorted_and_rotated(values &i64, length usize) i64 {
	if length > 256 { return -1 }
	if length == 0 { return 1 }
	unsafe {
		mut descents := 0
		for index in 0 .. length {
			value := values[index]
			if value < -2_147_483_648 || value > 2_147_483_647 { return -1 }
			next := (index + 1) % length
			if value > values[next] {
				descents++
				if descents > 1 { return 0 }
			}
		}
		return 1
	}
}
