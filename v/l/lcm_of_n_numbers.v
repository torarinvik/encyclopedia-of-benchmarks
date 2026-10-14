module lcm_of_n_numbers

// Fold a list of nonnegative values with overflow-safe Euclidean LCM.
@[export: 'lcm_of_n_numbers']
pub fn lcm_of_n_numbers(values &i64, length usize) i64 {
	for index in 0 .. length {
		if unsafe { values[index] } == 0 { return 0 }
	}
	mut accumulator := u64(1)
	maximum := u64(9223372036854775807)
	for index in 0 .. length {
		value := u64(unsafe { values[index] })
		mut left := accumulator
		mut right := value
		for right != 0 {
			remainder := left % right
			left = right
			right = remainder
		}
		reduced := accumulator / left
		if reduced > maximum / value { return -1 }
		accumulator = reduced * value
	}
	return i64(accumulator)
}
