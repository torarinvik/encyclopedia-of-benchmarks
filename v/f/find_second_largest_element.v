module find_second_largest_element

const invalid_result = i64(-9223372036854775807 - 1)
const int32_min_value = i64(-2147483648)
const int32_max_value = i64(2147483647)

@[export: 'find_second_largest_element']
pub fn find_second_largest_element(input &i64, length usize) i64 {
	if input == nil || length < 3 || length > 10001 { return invalid_result }
	unsafe {
		n := input[0]
		if n < 2 || n > 10000 || length != usize(n + 1) { return invalid_result }
		mut largest := int32_min_value
		for i in 0 .. int(n) {
			value := input[i + 1]
			if value < int32_min_value || value > int32_max_value { return invalid_result }
			if value > largest { largest = value }
		}
		mut second := int32_min_value - 1
		for i in 0 .. int(n) {
			value := input[i + 1]
			if value < largest && value > second { second = value }
		}
		if second == int32_min_value - 1 { return invalid_result }
		return second
	}
}
