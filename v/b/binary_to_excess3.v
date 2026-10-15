module binary_to_excess3

const max_text_length = 128
const max_magnitude = i64(4_611_686_018_427_387_904)

fn is_ascii_space(value i64) bool {
	return value == 32 || (value >= 9 && value <= 13)
}

fn is_binary_digit(value i64) bool {
	return value == i64(`0`) || value == i64(`1`)
}

// Parse an ASCII base-2 integer, add three, and format with minimum width four.
@[export: 'binary_to_excess3']
pub fn binary_to_excess3(values &i64, length usize, output &u8, output_capacity usize) i64 {
	if length == 0 || length > max_text_length { return -1 }
	mut start := usize(0)
	mut end := length
	for start < end && is_ascii_space(unsafe { values[start] }) { start++ }
	for end > start && is_ascii_space(unsafe { values[end - 1] }) { end-- }
	if start == end { return -1 }

	mut negative := false
	first := unsafe { values[start] }
	if first == i64(`+`) || first == i64(`-`) {
		negative = first == i64(`-`)
		start++
		if start == end { return -1 }
	}
	first = unsafe { values[start] }
	prefixed := end - start >= 2 && first == i64(`0`) &&
		(unsafe { values[start + 1] } == i64(`b`) || unsafe { values[start + 1] } == i64(`B`))
	if prefixed { start += 2 }
	if start == end { return -1 }

	digit_start := start
	mut allow_prefix_underscore := prefixed
	mut have_digit := false
	mut last_was_digit := false
	mut magnitude := i64(0)
	for index := start; index < end; index++ {
		value := unsafe { values[index] }
		if is_binary_digit(value) {
			digit := value - i64(`0`)
			if magnitude > (max_magnitude - digit) / 2 { return -1 }
			magnitude = magnitude * 2 + digit
			have_digit = true
			last_was_digit = true
			allow_prefix_underscore = false
		} else if value == i64(`_`) {
			if last_was_digit && index + 1 < end && is_binary_digit(unsafe { values[index + 1] }) {
				last_was_digit = false
			} else if allow_prefix_underscore && !have_digit && index == digit_start &&
				index + 1 < end && is_binary_digit(unsafe { values[index + 1] }) {
				allow_prefix_underscore = false
			} else {
				return -1
			}
		} else {
			return -1
		}
	}
	if !have_digit || !last_was_digit { return -1 }

	mut result := magnitude
	if negative { result = -result }
	result += 3
	result_is_negative := result < 0
	mut remaining := result
	if result_is_negative { remaining = -result }
	mut reversed := [64]u8{}
	mut digit_count := usize(0)
	for {
		reversed[digit_count] = u8(`0`) + u8(remaining % 2)
		digit_count++
		remaining /= 2
		if remaining == 0 { break }
	}

	sign_length := if result_is_negative { usize(1) } else { usize(0) }
	mut output_length := sign_length + digit_count
	if output_length < 4 { output_length = 4 }
	if output == nil || output_capacity < output_length { return -2 }
	mut position := usize(0)
	if result_is_negative {
		unsafe { output[position] = u8(`-`) }
		position++
	}
	digit_width := output_length - sign_length
	for _ in digit_count .. digit_width {
		unsafe { output[position] = u8(`0`) }
		position++
	}
	for digit_count > 0 {
		digit_count--
		unsafe { output[position] = reversed[digit_count] }
		position++
	}
	return i64(output_length)
}
