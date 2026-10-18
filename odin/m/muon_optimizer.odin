package muon_optimizer

import "core:c"
import "core:math"

MAX_GROUP_COUNT :: 4
MAX_ROWS :: 4
MAX_COLUMNS :: 4
MAX_MATRIX_ELEMENTS :: 16
MAX_GROUP_MATRIX_ELEMENTS :: 32
MAX_CALL_COUNT :: 8
MAX_VALID_INPUT_LENGTH :: c.size_t(271)
MAX_PARSEABLE_INPUT_LENGTH :: c.size_t(272)

finite_value :: proc(value: f64) -> bool {
	return !math.is_nan(value) && !math.is_inf(value)
}

orthogonalize :: proc(gradient: [^]f64, rows, columns, ns_steps: int, result: [^]f64) {
	transposed := rows < columns
	working_rows := if transposed then columns else rows
	working_columns := if transposed then rows else columns
	matrix: [MAX_MATRIX_ELEMENTS]f64
	for row := 0; row < rows; row += 1 {
		for column := 0; column < columns; column += 1 {
			if transposed {
				matrix[column*working_columns+row] = gradient[row*columns+column]
			} else {
				matrix[row*working_columns+column] = gradient[row*columns+column]
			}
		}
	}
	for _ in 0..<ns_steps {
		gram: [MAX_MATRIX_ELEMENTS]f64
		product: [MAX_MATRIX_ELEMENTS]f64
		for left := 0; left < working_columns; left += 1 {
			for right := 0; right < working_columns; right += 1 {
				sum := f64(0)
				for row := 0; row < working_rows; row += 1 {
					sum += matrix[row*working_columns+left] * matrix[row*working_columns+right]
				}
				gram[left*working_columns+right] = sum
			}
		}
		for row := 0; row < working_rows; row += 1 {
			for column := 0; column < working_columns; column += 1 {
				sum := f64(0)
				for inner := 0; inner < working_columns; inner += 1 {
					sum += matrix[row*working_columns+inner] * gram[inner*working_columns+column]
				}
				product[row*working_columns+column] = sum
			}
		}
		for row := 0; row < working_rows; row += 1 {
			for column := 0; column < working_columns; column += 1 {
				index := row*working_columns + column
				matrix[index] = 1.5*matrix[index] - 0.5*product[index]
			}
		}
	}
	for row := 0; row < rows; row += 1 {
		for column := 0; column < columns; column += 1 {
			if transposed {
				result[row*columns+column] = matrix[column*working_columns+row]
			} else {
				result[row*columns+column] = matrix[row*working_columns+column]
			}
		}
	}
}

@(export)
muon_optimizer :: proc "c" (input: [^]f64, input_length: c.size_t,
	output: [^]f64, output_capacity: c.size_t) -> i64 {
	if input == nil || input_length < 10 || input_length > MAX_PARSEABLE_INPUT_LENGTH do return -1
	for index := 0; index < int(input_length); index += 1 {
		if !finite_value(input[index]) do return -1
	}
	group_value, rows_value, columns_value := input[0], input[1], input[2]
	calls_value, steps_value := input[3], input[4]
	if group_value < 1.0 || group_value > f64(MAX_GROUP_COUNT) || rows_value < 1.0 || rows_value > f64(MAX_ROWS) ||
		columns_value < 1.0 || columns_value > f64(MAX_COLUMNS) || calls_value < 1.0 || calls_value > f64(MAX_CALL_COUNT) ||
		steps_value < 0.0 || steps_value > 5.0 do return -1
	group_count, rows, columns := int(group_value), int(rows_value), int(columns_value)
	call_count, ns_steps := int(calls_value), int(steps_value)
	if f64(group_count) != group_value || f64(rows) != rows_value || f64(columns) != columns_value ||
		f64(call_count) != calls_value || f64(ns_steps) != steps_value do return -1
	matrix_elements := rows * columns
	if matrix_elements > MAX_MATRIX_ELEMENTS || group_count*matrix_elements > MAX_GROUP_MATRIX_ELEMENTS ||
		call_count < group_count do return -1
	if input_length != c.size_t(7+call_count*(1+2*matrix_elements)) || input_length > MAX_VALID_INPUT_LENGTH do return -1
	learning_rate, momentum := input[5], input[6]
	if learning_rate < 0.0 || learning_rate > 0.25 || momentum < 0.0 || momentum > 0.99 do return -1

	ids: [MAX_CALL_COUNT]int
	event_params: [MAX_CALL_COUNT*MAX_MATRIX_ELEMENTS]f64
	event_gradients: [MAX_CALL_COUNT*MAX_MATRIX_ELEMENTS]f64
	seen: [MAX_GROUP_COUNT]bool
	cursor := 7
	for event := 0; event < call_count; event += 1 {
		id_value := input[cursor]
		if id_value < 0.0 || id_value >= f64(group_count) do return -1
		id := int(id_value)
		if f64(id) != id_value do return -1
		ids[event] = id
		seen[id] = true
		cursor += 1
		for element := 0; element < matrix_elements; element += 1 {
			value := input[cursor+element]
			if value < -10.0 || value > 10.0 do return -1
			event_params[event*matrix_elements+element] = value
		}
		cursor += matrix_elements
		for element := 0; element < matrix_elements; element += 1 {
			value := input[cursor+element]
			if value < -0.01 || value > 0.01 do return -1
			event_gradients[event*matrix_elements+element] = value
		}
		cursor += matrix_elements
	}
	for id := 0; id < group_count; id += 1 {
		if !seen[id] do return -1
	}
	group_elements := group_count * matrix_elements
	output_elements := 2 * group_elements
	if output == nil || output_capacity < c.size_t(output_elements) do return -2
	velocities: [MAX_GROUP_MATRIX_ELEMENTS]f64 = {}
	last_params: [MAX_GROUP_MATRIX_ELEMENTS]f64 = {}
	for event := 0; event < call_count; event += 1 {
		id := ids[event]
		state_offset := id * matrix_elements
		orthogonalized: [MAX_MATRIX_ELEMENTS]f64
		orthogonalize(&event_gradients[event*matrix_elements], rows, columns, ns_steps, &orthogonalized[0])
		for element := 0; element < matrix_elements; element += 1 {
			state_index := state_offset + element
			event_index := event * matrix_elements + element
			velocities[state_index] = momentum*velocities[state_index] + orthogonalized[element]
			last_params[state_index] = event_params[event_index] - learning_rate*velocities[state_index]
		}
	}
	for index := 0; index < group_elements; index += 1 {
		output[index] = last_params[index]
		output[group_elements+index] = velocities[index]
	}
	return i64(output_elements)
}
