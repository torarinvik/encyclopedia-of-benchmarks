module set_algebra

const max_set_size = 64
const max_result_size = 2 * max_set_size
const max_input_length = 4 + 2 * max_set_size

fn contains(values []i64, target i64) bool {
	for value in values { if value == target { return true } }
	return false
}
fn bool_to_i64(value bool) i64 {
	if value { return 1 }
	return 0
}
fn is_subset(left []i64, right []i64) bool {
	if left.len > right.len { return false }
	for value in left { if !contains(right, value) { return false } }
	return true
}
fn put_i64_le(mut output &u8, offset int, value i64) {
	mut bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8(bits & 255) }
		bits >>= 8
	}
}

@[export: 'set_algebra']
pub fn set_algebra(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 4 || length > max_input_length { return -1 }
	operation := unsafe { input[0] }
	left_raw := unsafe { input[1] }
	right_raw := unsafe { input[2] }
	query_key := unsafe { input[3] }
	if operation < 0 || operation > 8 || left_raw < 0 || left_raw > max_set_size || right_raw < 0 || right_raw > max_set_size || query_key < -1_000_000 || query_key > 1_000_000 { return -1 }
	left_length := int(left_raw)
	right_length := int(right_raw)
	if length != usize(4 + left_length + right_length) { return -1 }

	mut left := []i64{cap: max_set_size}
	mut right := []i64{cap: max_set_size}
	mut result := []i64{cap: max_result_size}
	unsafe {
		for i in 0 .. left_length {
			value := input[4 + i]
			if value < -1_000_000 || value > 1_000_000 { return -1 }
			if !contains(left, value) { left << value }
		}
		for i in 0 .. right_length {
			value := input[4 + left_length + i]
			if value < -1_000_000 || value > 1_000_000 { return -1 }
			if !contains(right, value) { right << value }
		}
	}

	if operation == 0 { result << bool_to_i64(contains(left, query_key)) }
	else if operation == 1 { result << bool_to_i64(is_subset(left, right)) }
	else if operation == 2 { result << bool_to_i64(left.len < right.len && is_subset(left, right)) }
	else if operation == 3 { result << bool_to_i64(is_subset(right, left)) }
	else if operation == 4 { result << bool_to_i64(right.len < left.len && is_subset(right, left)) }
	else if operation == 5 {
		for value in left { result << value }
		for value in right { if !contains(left, value) { result << value } }
	} else if operation == 6 {
		for value in left { if contains(right, value) { result << value } }
	} else if operation == 7 {
		for value in left { if !contains(right, value) { result << value } }
	} else {
		for value in left { if !contains(right, value) { result << value } }
		for value in right { if !contains(left, value) { result << value } }
	}
	for i := 1; i < result.len; i++ {
		value := result[i]
		mut j := i
		for j > 0 && result[j - 1] > value { result[j] = result[j - 1]; j-- }
		result[j] = value
	}
	output_bytes := result.len * 8
	if capacity < usize(output_bytes) || (output_bytes > 0 && unsafe { output == nil }) { return -2 }
	unsafe {
		for i, value in result { put_i64_le(mut output, i * 8, value) }
	}
	return i64(output_bytes)
}
