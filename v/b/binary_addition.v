module binary_addition

const max_operand_bits = 2047

// Add two packed binary strings and return their ASCII representation.
@[export: 'binary_addition']
pub fn binary_addition(values &i64, length usize, output &u8, output_capacity usize) i64 {
	if values == nil || length < 2 || length > 2 + 2 * max_operand_bits { return -1 }
	unsafe {
		if values[0] < 0 || values[0] > max_operand_bits || values[1] < 0 || values[1] > max_operand_bits { return -1 }
		first_length := usize(values[0])
		second_length := usize(values[1])
		if length != first_length + second_length + 2 { return -1 }
		for index in 0 .. first_length + second_length {
			if values[index + 2] < 0 || values[index + 2] > 1 { return -1 }
		}
		width := if first_length > second_length { first_length } else { second_length }
		if width == 0 { return 0 }
		mut reversed := [max_operand_bits + 1]u8{}
		mut result_length := usize(0)
		mut carry := i64(0)
		for offset in 0 .. width {
			first := if offset < first_length { values[2 + first_length - 1 - offset] } else { i64(0) }
			second := if offset < second_length { values[2 + first_length + second_length - 1 - offset] } else { i64(0) }
			sum := first + second + carry
			reversed[result_length] = u8(`0` + sum % 2)
			result_length++
			carry = sum / 2
		}
		if carry != 0 {
			reversed[result_length] = u8(`1`)
			result_length++
		}
		if output_capacity < result_length || output == nil { return -2 }
		for index in 0 .. result_length { output[index] = reversed[result_length - 1 - index] }
		return i64(result_length)
	}
}
