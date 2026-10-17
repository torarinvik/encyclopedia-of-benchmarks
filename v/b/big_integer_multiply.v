module big_integer_multiply

@[export: 'big_integer_multiply']
pub fn big_integer_multiply(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if input == nil || length < 4 || length > 66 { return -1 }
	unsafe {
		left_value := input[0]
		right_value := input[1]
		if left_value < 1 || left_value > 32 || right_value < 1 || right_value > 32 { return -1 }
		left_length := int(left_value)
		right_length := int(right_value)
		if int(length) != 2 + left_length + right_length { return -1 }
		right_start := 2 + left_length
		for index := 0; index < left_length; index++ {
			if input[2 + index] < 48 || input[2 + index] > 57 { return -1 }
		}
		for index := 0; index < right_length; index++ {
			if input[right_start + index] < 48 || input[right_start + index] > 57 { return -1 }
		}
		if (left_length > 1 && input[2] == 48) || (right_length > 1 && input[right_start] == 48) { return -1 }

		mut product := []u16{len: 64, init: 0}
		product_size := left_length + right_length
		is_zero := (left_length == 1 && input[2] == 48) || (right_length == 1 && input[right_start] == 48)
		if !is_zero {
			for i := 0; i < left_length; i++ {
				for j := 0; j < right_length; j++ {
					position := i + j
					multiplication := u16((input[2 + left_length - i - 1] - 48) *
						(input[right_start + right_length - j - 1] - 48))
					product[position + 1] += (product[position] + multiplication) / 10
					product[position] = (product[position] + multiplication) % 10
				}
			}
		}
		effective_size := product_size
		if is_zero { effective_size = 1 } else if product[product_size - 1] == 0 { effective_size-- }
		if output == nil || capacity < usize(effective_size) { return -2 }
		if is_zero {
			output[0] = u8(48)
		} else {
			for index := 0; index < effective_size; index++ {
				output[index] = u8(48 + int(product[effective_size - index - 1]))
			}
		}
		return i64(effective_size)
	}
}
