const max_group_count = 4
const max_rows = 4
const max_columns = 4
const max_matrix_elements = 16
const max_group_matrix_elements = 32
const max_call_count = 8
const max_valid_input_length = 271
const max_parseable_input_length = 272

fn finite_value(value f64) bool {
	return !value.is_nan() && !value.is_inf()
}

fn orthogonalize(gradient &f64, rows int, columns int, ns_steps int, mut result [16]f64) {
	unsafe {
		transposed := rows < columns
		working_rows := if transposed { columns } else { rows }
		working_columns := if transposed { rows } else { columns }
	mut matrix := [16]f64{}
	for row in 0 .. rows {
		for column in 0 .. columns {
			if transposed {
				matrix[column * working_columns + row] = gradient[row * columns + column]
			} else {
				matrix[row * working_columns + column] = gradient[row * columns + column]
			}
		}
	}
	for _ in 0 .. ns_steps {
		mut gram := [16]f64{}
		mut product := [16]f64{}
		for left in 0 .. working_columns {
			for right in 0 .. working_columns {
				mut sum := 0.0
				for row in 0 .. working_rows {
					sum += matrix[row * working_columns + left] * matrix[row * working_columns + right]
				}
				gram[left * working_columns + right] = sum
			}
		}
		for row in 0 .. working_rows {
			for column in 0 .. working_columns {
				mut sum := 0.0
				for inner in 0 .. working_columns {
					sum += matrix[row * working_columns + inner] * gram[inner * working_columns + column]
				}
				product[row * working_columns + column] = sum
			}
		}
		for row in 0 .. working_rows {
			for column in 0 .. working_columns {
				index := row * working_columns + column
				matrix[index] = 1.5 * matrix[index] - 0.5 * product[index]
			}
		}
	}
	for row in 0 .. rows {
		for column in 0 .. columns {
			if transposed {
				result[row * columns + column] = matrix[column * working_columns + row]
			} else {
				result[row * columns + column] = matrix[row * working_columns + column]
			}
		}
	}
	}
}

@[export: 'muon_optimizer']
pub fn muon_optimizer(input &f64, input_length usize, mut output &f64, output_capacity usize) i64 {
	unsafe {
		if input == nil || input_length < 10 || input_length > max_parseable_input_length { return -1 }
		for index in 0 .. input_length {
			if !finite_value(input[index]) { return -1 }
		}
		group_value, rows_value, columns_value := input[0], input[1], input[2]
		calls_value, steps_value := input[3], input[4]
		if group_value < 1.0 || group_value > f64(max_group_count) || rows_value < 1.0 || rows_value > f64(max_rows) ||
			columns_value < 1.0 || columns_value > f64(max_columns) || calls_value < 1.0 || calls_value > f64(max_call_count) ||
			steps_value < 0.0 || steps_value > 5.0 { return -1 }
		group_count, rows, columns := int(group_value), int(rows_value), int(columns_value)
		call_count, ns_steps := int(calls_value), int(steps_value)
		if f64(group_count) != group_value || f64(rows) != rows_value || f64(columns) != columns_value ||
			f64(call_count) != calls_value || f64(ns_steps) != steps_value { return -1 }
		matrix_elements := rows * columns
		if matrix_elements > max_matrix_elements || group_count * matrix_elements > max_group_matrix_elements ||
			call_count < group_count { return -1 }
		if input_length != usize(7 + call_count * (1 + 2 * matrix_elements)) || input_length > max_valid_input_length { return -1 }
		learning_rate, momentum := input[5], input[6]
		if learning_rate < 0.0 || learning_rate > 0.25 || momentum < 0.0 || momentum > 0.99 { return -1 }

		mut ids := [max_call_count]int{}
		mut event_params := [max_call_count * max_matrix_elements]f64{}
		mut event_gradients := [max_call_count * max_matrix_elements]f64{}
		mut seen := [max_group_count]bool{}
		mut cursor := 7
		for event in 0 .. call_count {
			id_value := input[cursor]
			if id_value < 0.0 || id_value >= f64(group_count) { return -1 }
			id := int(id_value)
			if f64(id) != id_value { return -1 }
			ids[event] = id
			seen[id] = true
			cursor++
			for element in 0 .. matrix_elements {
				value := input[cursor + element]
				if value < -10.0 || value > 10.0 { return -1 }
				event_params[event * matrix_elements + element] = value
			}
			cursor += matrix_elements
			for element in 0 .. matrix_elements {
				value := input[cursor + element]
				if value < -0.01 || value > 0.01 { return -1 }
				event_gradients[event * matrix_elements + element] = value
			}
			cursor += matrix_elements
		}
		for id in 0 .. group_count {
			if !seen[id] { return -1 }
		}
		group_elements := group_count * matrix_elements
		output_elements := 2 * group_elements
		if output == nil || output_capacity < usize(output_elements) { return -2 }
		mut velocities := [max_group_matrix_elements]f64{}
		mut last_params := [max_group_matrix_elements]f64{}
		for event in 0 .. call_count {
			id := ids[event]
			state_offset := id * matrix_elements
			mut orthogonalized := [max_matrix_elements]f64{}
			orthogonalize(&event_gradients[event * matrix_elements], rows, columns, ns_steps, mut orthogonalized)
			for element in 0 .. matrix_elements {
				state_index := state_offset + element
				event_index := event * matrix_elements + element
				velocities[state_index] = momentum * velocities[state_index] + orthogonalized[element]
				last_params[state_index] = event_params[event_index] - learning_rate * velocities[state_index]
			}
		}
		for index in 0 .. group_elements {
			output[index] = last_params[index]
			output[group_elements + index] = velocities[index]
		}
		return i64(output_elements)
	}
}
