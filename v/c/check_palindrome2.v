module check_palindrome2

const max_length = 1024

fn lower_ascii(value i64) i64 {
	if value >= 65 && value <= 90 { return value + 32 }
	return value
}

@[export: 'check_palindrome2']
pub fn check_palindrome2(values &i64, length usize, output &u8, output_capacity usize) i64 {
	if length > max_length { return -1 }
	if unsafe { values == nil } && length != 0 { return -1 }
	for index in 0 .. int(length) {
		value := unsafe { values[index] }
		if value < 32 || value > 126 { return -1 }
	}
	mut start := 0
	mut end := int(length)
	for start < end && unsafe { values[start] } == 32 { start += 1 }
	for end > start && unsafe { values[end - 1] } == 32 { end -= 1 }
	normalized_length := end - start
	if normalized_length == 0 || (normalized_length == 1 && unsafe { values[start] } == 48) { return -1 }
	mut palindrome := true
	for left in 0 .. normalized_length / 2 {
		right := normalized_length - left - 1
		if lower_ascii(unsafe { values[start + left] }) != lower_ascii(unsafe { values[start + right] }) {
			palindrome = false
		}
	}
	suffix := if palindrome { " - a palindrome string.\n" } else { " - not a palindrome string.\n" }
	required := normalized_length + suffix.len
	if unsafe { output == nil } || output_capacity < required { return -2 }
	unsafe {
		for index in 0 .. normalized_length {
			output[index] = u8(lower_ascii(values[start + index]))
		}
		for index in 0 .. suffix.len {
			output[normalized_length + index] = suffix[index]
		}
	}
	return i64(required)
}
