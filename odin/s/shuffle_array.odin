package shuffle_array

import "core:c"

MAX_N :: 32
MAX_PARSEABLE_INPUT_LENGTH :: 67
MAX_OUTPUT_BYTES :: 520
I32_MIN :: i64(-2_147_483_648)
I32_MAX :: i64(2_147_483_647)

store_i64_le :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 {
		output[offset + byte] = u8(bits & 255)
		bits >>= 8
	}
}

@(export)
shuffle_array :: proc "c" (input: [^]i64, input_length: c.size_t,
	output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || input_length < 2 || input_length > MAX_PARSEABLE_INPUT_LENGTH do return -1
	variant := input[0]
	n_value := input[1]
	if (variant != 0 && variant != 1) || n_value < 0 || n_value > MAX_N do return -1
	n := int(n_value)
	value_count := n
	if variant == 1 { value_count = 2 * n }
	draw_count := 0
	if variant == 0 && n > 0 { draw_count = n - 1 }
	if int(input_length) != 2 + value_count + draw_count do return -1

	result_values: [2 * MAX_N]i64
	result_count := value_count
	for index in 0..<value_count {
		value := input[2 + index]
		if value < I32_MIN || value > I32_MAX do return -1
		result_values[index] = value
	}

	if variant == 0 {
		for draw_index in 0..<draw_count {
			current_index := n - 1 - draw_index
			chosen_value := input[2 + n + draw_index]
			if chosen_value < 0 || chosen_value > i64(current_index) do return -1
			chosen_index := int(chosen_value)
			temporary := result_values[current_index]
			result_values[current_index] = result_values[chosen_index]
			result_values[chosen_index] = temporary
		}
	} else {
		for index in 0..<n {
			result_values[2 * index] = input[2 + index]
			result_values[2 * index + 1] = input[2 + n + index]
		}
	}

	output_bytes := 8 * (result_count + 1)
	if output_bytes > MAX_OUTPUT_BYTES || output == nil || int(output_capacity) < output_bytes do return -2
	store_i64_le(output, 0, i64(result_count))
	for index in 0..<result_count { store_i64_le(output, 8 * (index + 1), result_values[index]) }
	return i64(output_bytes)
}
