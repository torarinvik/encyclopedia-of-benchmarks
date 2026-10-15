module find_the_difference

const max_string_length = 4096
const max_packed_length = 8195

// Return the lowercase byte added to t by subtracting the two character sums.
@[export: 'find_the_difference']
pub fn find_the_difference(input &i64, length usize) i64 {
	if length < 2 || length > max_packed_length { return -1 }
	if unsafe { input[0] < 0 || input[0] > max_string_length || input[1] < 1 || input[1] > max_string_length + 1 } { return -1 }
	s_length := usize(unsafe { input[0] })
	t_length := usize(unsafe { input[1] })
	if t_length != s_length + 1 || length != 2 + s_length + t_length { return -1 }
	mut sum_s := i64(0)
	mut sum_t := i64(0)
	for index in 0 .. s_length {
		value := unsafe { input[2 + index] }
		if value < 97 || value > 122 { return -1 }
		sum_s += value
	}
	t_start := 2 + s_length
	for index in 0 .. t_length {
		value := unsafe { input[t_start + index] }
		if value < 97 || value > 122 { return -1 }
		sum_t += value
	}
	difference := sum_t - sum_s
	if difference < 97 || difference > 122 { return -1 }
	return difference
}
