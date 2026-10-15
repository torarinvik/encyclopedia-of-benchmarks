package serialize_deserialize_binary_tree

import "core:c"

MAX_INPUT :: 2200
MAX_NODES :: 127

ascii_space :: proc(value: i64) -> bool { return value == 32 || (value >= 9 && value <= 13) }

parse_integer :: proc(input: [^]i64, first_arg, last_arg: int, result: ^i64) -> bool {
	first, last := first_arg, last_arg
	for first < last && ascii_space(input[first]) { first += 1 }
	for last > first && ascii_space(input[last - 1]) { last -= 1 }
	if first == last do return false
	negative := false
	if input[first] == 45 || input[first] == 43 { negative = input[first] == 45; first += 1 }
	if first == last do return false
	limit := i64(2147483647)
	if negative { limit = 2147483648 }
	magnitude := i64(0)
	for i := first; i < last; i += 1 {
		if input[i] < 48 || input[i] > 57 do return false
		digit := input[i] - 48
		if magnitude > (limit - digit) / 10 do return false
		magnitude = magnitude * 10 + digit
	}
	if negative { result^ = -magnitude } else { result^ = magnitude }
	return true
}

emit_integer :: proc(output: [^]u8, position_arg: int, number: i64) -> int {
	position := position_arg
	magnitude := number
	if number < 0 { output[position] = 45; position += 1; magnitude = -number }
	var digits: [10]u8
	count := 0
	for {
		digits[count] = u8(48 + magnitude % 10)
		count += 1
		magnitude /= 10
		if magnitude == 0 do break
	}
	for count > 0 { count -= 1; output[position] = digits[count]; position += 1 }
	return position
}

@(export)
serialize_deserialize_binary_tree :: proc "c" (values: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if values == nil || length == 0 || length > MAX_INPUT do return -1
	for i := c.size_t(0); i < length; i += 1 do if values[i] < 0 || values[i] > 127 do return -1
	var encoded: [MAX_INPUT]u8
	position, slots, nodes, written := 0, 1, 0, 0
	for position < int(length) {
		if slots == 0 do return -1
		start := position
		for position < int(length) && values[position] != 44 { position += 1 }
		finish := position
		if start == finish do return -1
		is_null := finish - start == 4 && values[start] == 110 && values[start + 1] == 117 && values[start + 2] == 108 && values[start + 3] == 108
		if written > 0 { encoded[written] = 44; written += 1 }
		if is_null {
			for ch in [4]u8{110, 117, 108, 108} { encoded[written] = ch; written += 1 }
		} else {
			var number: i64
			if !parse_integer(values, start, finish, &number) do return -1
			nodes += 1
			if nodes > MAX_NODES do return -1
			written = emit_integer(&encoded[0], written, number)
		}
		slots -= 1
		if !is_null { slots += 2 }
		if position < int(length) { position += 1; if position == int(length) do return -1 }
	}
	if slots != 0 do return -1
	if output == nil || output_capacity < c.size_t(written) do return -2
	for i := 0; i < written; i += 1 do output[i] = encoded[i]
	return i64(written)
}
