@[export: 'large_number_add']
pub fn large_number_add(input &i64, input_length usize, mut output &u8, output_capacity usize) i64 {
	unsafe {
		if input == nil || input_length < 2 || input_length > 131 { return -1 }
		left_length_value := input[0]
		right_length_value := input[1]
		if left_length_value < 1 || left_length_value > 64 ||
			right_length_value < 1 || right_length_value > 64 { return -1 }
		left_length := int(left_length_value)
		right_length := int(right_length_value)
		if input_length != usize(2+left_length+right_length) { return -1 }

		mut left := [64]u8{}
		mut right := [64]u8{}
		for i in 0 .. left_length {
			digit := input[2+i]
			if digit < 48 || digit > 57 || (i == 0 && left_length > 1 && digit == 48) { return -1 }
			left[left_length-i-1] = u8(digit-48)
		}
		for i in 0 .. right_length {
			digit := input[2+left_length+i]
			if digit < 48 || digit > 57 || (i == 0 && right_length > 1 && digit == 48) { return -1 }
			right[right_length-i-1] = u8(digit-48)
		}

		mut sum := [65]u8{}
		mut sum_length := 0
		mut carry := u8(0)
		longer := if left_length > right_length { left_length } else { right_length }
		for sum_length < longer || carry != 0 {
			mut total := carry
			if sum_length < right_length { total += right[sum_length] }
			if sum_length < left_length { total += left[sum_length] }
			sum[sum_length] = total % 10
			carry = total / 10
			sum_length++
		}
		mut staged := [65]u8{}
		for i in 0 .. sum_length { staged[i] = u8(48) + sum[sum_length-i-1] }
		if output == nil || output_capacity < sum_length { return -2 }
		for i in 0 .. sum_length { output[i] = staged[i] }
		return i64(sum_length)
	}
}
