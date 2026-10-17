package big_integer_multiply

import "core:c"

big_integer_multiply :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 4 || length > 66 do return -1
	left_value, right_value := input[0], input[1]
	if left_value < 1 || left_value > 32 || right_value < 1 || right_value > 32 do return -1
	left_length, right_length := c.size_t(left_value), c.size_t(right_value)
	if length != 2 + left_length + right_length do return -1
	right_start := 2 + left_length
	for index := c.size_t(0); index < left_length; index += 1 {
		if input[2 + index] < 48 || input[2 + index] > 57 do return -1
	}
	for index := c.size_t(0); index < right_length; index += 1 {
		if input[right_start + index] < 48 || input[right_start + index] > 57 do return -1
	}
	if (left_length > 1 && input[2] == 48) || (right_length > 1 && input[right_start] == 48) do return -1

	product: [64]u16
	for index := 0; index < 64; index += 1 { product[index] = 0 }
	product_size := left_length + right_length
	is_zero := (left_length == 1 && input[2] == 48) || (right_length == 1 && input[right_start] == 48)
	if !is_zero {
		for i := c.size_t(0); i < left_length; i += 1 {
			for j := c.size_t(0); j < right_length; j += 1 {
				position := i + j
				multiplication := u16((input[2 + left_length - i - 1] - 48) *
					(input[right_start + right_length - j - 1] - 48))
				product[position + 1] += (product[position] + multiplication) / 10
				product[position] = (product[position] + multiplication) % 10
			}
		}
	}
	effective_size := product_size
	if is_zero {
		effective_size = 1
	} else if product[product_size - 1] == 0 {
		effective_size -= 1
	}
	if output == nil || capacity < effective_size do return -2
	if is_zero {
		output[0] = 48
	} else {
		for index := c.size_t(0); index < effective_size; index += 1 {
			output[index] = u8(48 + product[effective_size - index - 1])
		}
	}
	return i64(effective_size)
}
