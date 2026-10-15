module validate_subsequence

@[export: 'validate_subsequence']
pub fn validate_subsequence(values &i64, length usize) i64 {
	if length < 2 || length > 8194 || isnil(values) {
		return -1
	}
	array_length_value := unsafe { values[0] }
	sequence_length_value := unsafe { values[1] }
	if array_length_value < 0 || array_length_value > 4096 || sequence_length_value < 0 || sequence_length_value > 4096 {
		return -1
	}
	array_length := int(array_length_value)
	sequence_length := int(sequence_length_value)
	if length != 2 + array_length + sequence_length {
		return -1
	}
	for i := 2; i < length; i++ {
		value := unsafe { values[i] }
		if value < -2147483648 || value > 2147483647 {
			return -1
		}
	}
	if array_length == 0 {
		return 0
	}
	if sequence_length == 0 {
		return 1
	}
	sequence_start := 2 + array_length
	mut array_index := 0
	mut sequence_index := 0
	for sequence_index < sequence_length && array_index < array_length {
		if unsafe { values[sequence_start + sequence_index] } == unsafe { values[2 + array_index] } {
			sequence_index++
		}
		array_index++
	}
	return if sequence_index == sequence_length { 1 } else { 0 }
}
