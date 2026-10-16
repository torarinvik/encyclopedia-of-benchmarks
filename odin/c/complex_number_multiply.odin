package complex_number_multiply

import "core:c"

parse_component :: proc(input: [^]i64, start, ending: int, result: ^i64) -> bool {
	position := start
	negative := false
	if position < ending && input[position] == 45 { negative = true; position += 1 }
	if position == ending do return false
	magnitude := i64(0)
	for position < ending {
		if input[position] < 48 || input[position] > 57 do return false
		digit := input[position] - 48
		if magnitude > (32767 - digit) / 10 do return false
		magnitude = magnitude * 10 + digit
		position += 1
	}
	result^ = if negative then -magnitude else magnitude
	return true
}

parse_complex :: proc(input: [^]i64, start, text_length: int, real, imaginary: ^i64) -> bool {
	if text_length < 4 || text_length > 64 || input[start+text_length-1] != 105 do return false
	separator := -1
	for index := 0; index < text_length-1; index += 1 {
		if input[start+index] == 43 {
			if separator >= 0 do return false
			separator = index
		}
	}
	if separator < 0 do return false
	return parse_component(input, start, start+separator, real)
		&& parse_component(input, start+separator+1, start+text_length-1, imaginary)
}

decimal_length :: proc(value: i64) -> int {
	length := if value < 0 then 1 else 0
	magnitude := if value < 0 then -value else value
	if magnitude == 0 do return length + 1
	for magnitude > 0 { length += 1; magnitude /= 10 }
	return length
}

append_decimal :: proc(output: [^]u8, index: int, value: i64) -> int {
	write := index
	magnitude := value
	if magnitude < 0 { output[write] = 45; write += 1; magnitude = -magnitude }
	start := write
	if magnitude == 0 { output[write] = 48; return write + 1 }
	for magnitude > 0 { output[write] = u8(48 + magnitude % 10); write += 1; magnitude /= 10 }
	right := write - 1
	for start < right {
		temporary := output[start]; output[start] = output[right]; output[right] = temporary
		start += 1; right -= 1
	}
	return write
}

@(export)
complex_number_multiply :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > c.size_t(130) do return -1
	raw_left_length, raw_right_length := input[0], input[1]
	if raw_left_length < 4 || raw_left_length > 64 || raw_right_length < 4 || raw_right_length > 64 do return -1
	left_length, right_length := int(raw_left_length), int(raw_right_length)
	if length != c.size_t(2+left_length+right_length) do return -1
	for index := 2; index < int(length); index += 1 { if input[index] < 0 || input[index] > 127 do return -1 }

	left_real, left_imaginary, right_real, right_imaginary := i64(0), i64(0), i64(0), i64(0)
	if !parse_complex(input, 2, left_length, &left_real, &left_imaginary) ||
		!parse_complex(input, 2+left_length, right_length, &right_real, &right_imaginary) do return -1
	real := left_real*right_real - left_imaginary*right_imaginary
	imaginary := left_real*right_imaginary + left_imaginary*right_real
	needed := decimal_length(real) + decimal_length(imaginary) + 2
	if output == nil || capacity < c.size_t(needed) do return -2

	written := append_decimal(output, 0, real)
	output[written] = 43
	written += 1
	written = append_decimal(output, written, imaginary)
	output[written] = 105
	return i64(written + 1)
}
