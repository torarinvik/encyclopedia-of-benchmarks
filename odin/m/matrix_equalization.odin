package matrix_equalization

import "core:c"

// Minimum updates needed to equalize a vector with a fixed step size.
@(export)
matrix_equalization :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	max_vector_length :: 64
	max_input_length :: 66
	if input == nil || length < 2 || length > max_input_length do return -1
	vector_length := int(length) - 1
	if vector_length > max_vector_length || input[0] < 1 || input[0] > i64(vector_length) do return -1
	step_size := int(input[0])
	minimum_updates := vector_length

	for target_index := 0; target_index < vector_length; target_index += 1 {
		seen := false
		for previous := 0; previous < target_index; previous += 1 {
			if input[previous + 1] == input[target_index + 1] {
				seen = true
				break
			}
		}
		if seen do continue

		updates := 0
		index := 0
		for index < vector_length {
			if input[index + 1] == input[target_index + 1] {
				index += 1
			} else {
				updates += 1
				index += step_size
			}
		}
		if updates < minimum_updates do minimum_updates = updates
	}
	return i64(minimum_updates)
}
