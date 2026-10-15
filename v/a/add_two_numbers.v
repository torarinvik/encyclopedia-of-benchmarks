module add_two_numbers

const max_digits = 1024

// Add reverse-order decimal digit lists with a carry propagated per node.
@[export: 'add_two_numbers']
pub fn add_two_numbers(input &i64, length usize, output &u8, output_capacity usize) i64 {
	if length < 2 || length > 2050 { return -1 }
	unsafe {
		if input[0] < 0 || input[0] > max_digits || input[1] < 0 || input[1] > max_digits { return -1 }
		first_length := usize(input[0])
		second_length := usize(input[1])
		if length != first_length + second_length + 2 { return -1 }
		for index in 0 .. first_length + second_length {
			if input[index + 2] < 0 || input[index + 2] > 9 { return -1 }
		}
		digit_count := if first_length > second_length { first_length } else { second_length }
		mut digits := []u8{len: max_digits + 1, init: 0}
		mut result_length := usize(0)
		mut carry := i64(0)
		mut index := usize(0)
		for index < digit_count || carry != 0 {
			first := if index < first_length { input[index + 2] } else { i64(0) }
			second := if index < second_length { input[index + 2 + first_length] } else { i64(0) }
			sum := first + second + carry
			digits[result_length] = u8(sum % 10)
			result_length++
			carry = sum / 10
			index++
		}
		if output_capacity < result_length || (result_length != 0 && output == nil) { return -2 }
		for position in 0 .. result_length { output[position] = digits[position] }
		return i64(result_length)
	}
}
