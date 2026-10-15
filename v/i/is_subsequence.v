module is_subsequence

const max_sequence_length = 4096
const max_packed_length = 8194

fn is_unicode_scalar(value i64) bool {
	return value >= 0 && value <= 1_114_111 && !(value >= 55_296 && value <= 57_343)
}

@[export: 'is_subsequence']
pub fn is_subsequence(input &i64, length usize) i64 {
	if length < 2 || length > usize(max_packed_length) || isnil(input) { return -1 }
	main_length_value := unsafe { input[0] }
	subsequence_length_value := unsafe { input[1] }
	if main_length_value < 0 || main_length_value > i64(max_sequence_length) ||
		subsequence_length_value < 0 || subsequence_length_value > i64(max_sequence_length) { return -1 }
	main_length := int(main_length_value)
	subsequence_length := int(subsequence_length_value)
	if length != 2 + main_length + subsequence_length { return -1 }
	for index in 2 .. length {
		if !is_unicode_scalar(unsafe { input[index] }) { return -1 }
	}

	subsequence_start := 2 + main_length
	mut main_index := 0
	mut subsequence_index := 0
	for subsequence_index < subsequence_length && main_index < main_length {
		if unsafe { input[subsequence_start + subsequence_index] } == unsafe { input[2 + main_index] } {
			subsequence_index++
		}
		main_index++
	}
	return if subsequence_index == subsequence_length { 1 } else { 0 }
}
