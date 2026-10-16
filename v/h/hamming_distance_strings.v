module hamming_distance_strings

@[export: 'hamming_distance_strings']
pub fn hamming_distance_strings(input &i64, length usize) i64 {
	if unsafe { input == nil } || length < 2 || length > 260 { return -1 }
	left_length := input[0]
	right_length := input[1]
	if left_length < 0 || left_length > 128 || right_length < 0 || right_length > 128 { return -1 }
	if length != usize(2 + left_length + right_length) { return -1 }
	for index in 2 .. int(length) { if input[index] < 0 || input[index] > 255 { return -1 } }
	if left_length != right_length { return -1 }
	mut distance := i64(0)
	for index in 0 .. int(left_length) { if input[2 + index] != input[2 + int(left_length) + index] { distance++ } }
	return distance
}
