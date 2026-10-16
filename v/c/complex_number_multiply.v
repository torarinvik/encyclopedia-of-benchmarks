fn parse_component(input &i64, start int, ending int) i64 {
	mut position := start
	mut negative := false
	if position < ending && unsafe { input[position] } == 45 { negative = true; position++ }
	if position == ending { return -32768 }
	mut magnitude := i64(0)
	for position < ending {
		byte := unsafe { input[position] }
		if byte < 48 || byte > 57 { return -32768 }
		digit := byte - 48
		if magnitude > (32767 - digit) / 10 { return -32768 }
		magnitude = magnitude * 10 + digit
		position++
	}
	return if negative { -magnitude } else { magnitude }
}

fn decimal_length(value i64) int {
	mut length := if value < 0 { 1 } else { 0 }
	mut magnitude := if value < 0 { -value } else { value }
	if magnitude == 0 { return length + 1 }
	for magnitude > 0 { length++; magnitude /= 10 }
	return length
}

fn append_decimal(mut output &u8, index int, value i64) int {
	mut write := index
	mut magnitude := value
	if magnitude < 0 {
		unsafe { output[write] = 45 }
		write++
		magnitude = -magnitude
	}
	start := write
	if magnitude == 0 { unsafe { output[write] = 48 }; return write + 1 }
	for magnitude > 0 {
		unsafe { output[write] = u8(48 + magnitude % 10) }
		write++
		magnitude /= 10
	}
	mut left := start
	mut right := write - 1
	for left < right {
		unsafe { temporary := output[left]; output[left] = output[right]; output[right] = temporary }
		left++
		right--
	}
	return write
}

@[export: 'complex_number_multiply']
pub fn complex_number_multiply(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 2 || length > 130 { return -1 }
	left_length_raw := unsafe { input[0] }
	right_length_raw := unsafe { input[1] }
	if left_length_raw < 4 || left_length_raw > 64 || right_length_raw < 4 || right_length_raw > 64 { return -1 }
	left_length := int(left_length_raw)
	right_length := int(right_length_raw)
	if length != usize(2 + left_length + right_length) { return -1 }
	for index in 2 .. int(length) {
		byte := unsafe { input[index] }
		if byte < 0 || byte > 127 { return -1 }
	}

	mut left_separator := -1
	for index in 0 .. left_length - 1 {
		if unsafe { input[2 + index] } == 43 {
			if left_separator >= 0 { return -1 }
			left_separator = index
		}
	}
	if left_separator < 0 || unsafe { input[2 + left_length - 1] } != 105 { return -1 }
	left_real := parse_component(input, 2, 2 + left_separator)
	left_imaginary := parse_component(input, 2 + left_separator + 1, 2 + left_length - 1)
	if left_real == -32768 || left_imaginary == -32768 { return -1 }

	right_start := 2 + left_length
	mut right_separator := -1
	for index in 0 .. right_length - 1 {
		if unsafe { input[right_start + index] } == 43 {
			if right_separator >= 0 { return -1 }
			right_separator = index
		}
	}
	if right_separator < 0 || unsafe { input[right_start + right_length - 1] } != 105 { return -1 }
	right_real := parse_component(input, right_start, right_start + right_separator)
	right_imaginary := parse_component(input, right_start + right_separator + 1, right_start + right_length - 1)
	if right_real == -32768 || right_imaginary == -32768 { return -1 }

	real := left_real * right_real - left_imaginary * right_imaginary
	imaginary := left_real * right_imaginary + left_imaginary * right_real
	needed := decimal_length(real) + decimal_length(imaginary) + 2
	if unsafe { output == nil } || capacity < usize(needed) { return -2 }
	mut written := append_decimal(mut output, 0, real)
	unsafe { output[written] = 43 }
	written++
	written = append_decimal(mut output, written, imaginary)
	unsafe { output[written] = 105 }
	return i64(written + 1)
}
