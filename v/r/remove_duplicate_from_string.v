module remove_duplicate_from_string

const max_text_length = 512
const max_input_length = max_text_length + 2

@[export: 'remove_duplicate_from_string']
pub fn remove_duplicate_from_string(input &i64, length usize, output &u8, output_capacity usize) i64 {
	if isnil(input) || length < 1 || length > usize(max_input_length) { return -1 }
	text_length_value := unsafe { input }
	if text_length_value < 0 || text_length_value > max_text_length { return -1 }
	text_length := int(text_length_value)
	if length != usize(1 + text_length) { return -1 }
	mut result := []u8{len: max_text_length}
	mut seen := []bool{len: 128}
	mut result_length := 0
	for index in 0 .. text_length {
		value := unsafe { input[index + 1] }
		if value < 0 || value > 127 { return -1 }
		byte := int(value)
		if !seen[byte] {
			seen[byte] = true
			result[result_length] = u8(value)
			result_length++
		}
	}
	if output_capacity < usize(result_length) || (result_length != 0 && isnil(output)) { return -2 }
	for index in 0 .. result_length { unsafe { output[index] = result[index] } }
	return i64(result_length)
}
