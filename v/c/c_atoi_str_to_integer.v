module c_atoi_str_to_integer

const max_input_length = 4096
const int32_max_value = i64(2147483647)
const int32_min_magnitude = i64(2147483648)

// Parse C ASCII whitespace, optional sign, initial digits, and NUL termination.
@[export: 'c_atoi_str_to_integer']
pub fn c_atoi_str_to_integer(input &i64, length usize) i64 {
	if length > max_input_length { return -2 }
	unsafe {
		for position in 0 .. length {
			if input[position] < 0 || input[position] > 127 { return -2 }
		}
		mut index := usize(0)
		for index < length && input[index] != 0 && ((input[index] >= 9 && input[index] <= 13) || input[index] == 32) { index++ }
		mut negative := false
		if index < length && input[index] != 0 && (input[index] == 43 || input[index] == 45) {
			negative = input[index] == 45
			index++
		}
		mut limit := int32_max_value
		if negative { limit = int32_min_magnitude }
		mut magnitude := i64(0)
		for index < length && input[index] != 0 && input[index] >= 48 && input[index] <= 57 {
			digit := input[index] - 48
			if magnitude > limit / 10 || (magnitude == limit / 10 && digit > limit % 10) {
				if negative { return -int32_min_magnitude }
				return int32_max_value
			}
			magnitude = magnitude * 10 + digit
			index++
		}
		if negative { return -magnitude }
		return magnitude
	}
}
