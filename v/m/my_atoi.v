module my_atoi

const max_input_length = 256
const int32_max_value = i64(2147483647)
const int32_min_magnitude = i64(2147483648)
const invalid_result = i64(-9223372036854775807 - 1)

@[export: 'my_atoi']
pub fn my_atoi(input &i64, length usize) i64 {
	if unsafe { input == nil } { return 0 }
	if length > max_input_length { return invalid_result }
	unsafe {
		for i in 0 .. length {
			if input[i] < 0 || input[i] > 127 { return invalid_result }
		}
		mut start := usize(0)
		mut end := length
		for start < end && input[start] <= 32 { start++ }
		for end > start && input[end - 1] <= 32 { end-- }
		if start == end { return 0 }

		mut negative := false
		if input[start] == 43 || input[start] == 45 {
			negative = input[start] == 45
			start++
		}
		mut limit := int32_max_value
		if negative { limit = int32_min_magnitude }
		mut magnitude := i64(0)
		for start < end && input[start] >= 48 && input[start] <= 57 {
			digit := input[start] - 48
			if magnitude > limit / 10 || (magnitude == limit / 10 && digit > limit % 10) {
				if negative { return -int32_min_magnitude }
				return int32_max_value
			}
			magnitude = magnitude * 10 + digit
			start++
		}
		if negative { return -magnitude }
		return magnitude
	}
}
