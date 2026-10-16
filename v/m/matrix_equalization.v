module matrix_equalization

// Minimum updates needed to equalize a vector with a fixed step size.
@[export: 'matrix_equalization']
pub fn matrix_equalization(input &i64, length usize) i64 {
	if length < 2 || length > 66 || unsafe { input == nil } { return -1 }
	unsafe {
		vector_length := int(length) - 1
		if vector_length > 64 || input[0] < 1 || input[0] > i64(vector_length) { return -1 }
		step_size := int(input[0])
		mut minimum_updates := vector_length

		for target_index in 0 .. vector_length {
			mut seen := false
			for previous in 0 .. target_index {
				if input[previous + 1] == input[target_index + 1] {
					seen = true
					break
				}
			}
			if seen { continue }

			mut updates := 0
			mut index := 0
			for index < vector_length {
				if input[index + 1] == input[target_index + 1] {
					index++
				} else {
					updates++
					index += step_size
				}
			}
			if updates < minimum_updates { minimum_updates = updates }
		}
		return i64(minimum_updates)
	}
}
