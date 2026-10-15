package cantor_set

import "core:c"

MAX_LEVEL :: 6
SCALE :: i64(1_000_000)

put_byte :: proc "contextless" (output: [^]u8, capacity: c.size_t, length: ^c.size_t, value: u8) -> bool {
	if length^ >= capacity do return false
	output[length^] = value
	length^ += 1
	return true
}

put_uint :: proc "contextless" (output: [^]u8, capacity: c.size_t, length: ^c.size_t, value: i64) -> bool {
	digits: [20]u8
	count := 0
	remaining := value
	for {
		digits[count] = u8(48 + remaining % 10)
		count += 1
		remaining /= 10
		if remaining == 0 do break
	}
	for count > 0 {
		count -= 1
		if !put_byte(output, capacity, length, digits[count]) do return false
	}
	return true
}

put_fixed :: proc "contextless" (output: [^]u8, capacity: c.size_t, length: ^c.size_t, ticks: i64) -> bool {
	fraction := ticks % SCALE
	if !put_uint(output, capacity, length, ticks / SCALE) || !put_byte(output, capacity, length, u8('.')) do return false
	for divisor := i64(100_000); divisor > 0; divisor /= 10 {
		digit := (fraction / divisor) % 10
		if !put_byte(output, capacity, length, u8(48 + digit)) do return false
	}
	return true
}

// Render source-style Cantor levels with integer ternary interval positions.
@(export)
cantor_set :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length != 3 do return -1
	start, ending, max_level := input[0], input[1], input[2]
	if start < 0 || start > ending || ending > 100_000 || max_level < 0 || max_level > MAX_LEVEL do return -1
	if output == nil do return -2
	span := ending - start
	positions: [64]i64 = {}
	next: [64]i64 = {}
	interval_count := 1
	output_length := c.size_t(0)
	denominator := i64(1)
	for level := i64(0); level <= max_level; level += 1 {
		if !put_byte(output, capacity, &output_length, u8('L')) do return -2
		if !put_byte(output, capacity, &output_length, u8('e')) do return -2
		if !put_byte(output, capacity, &output_length, u8('v')) do return -2
		if !put_byte(output, capacity, &output_length, u8('e')) do return -2
		if !put_byte(output, capacity, &output_length, u8('l')) do return -2
		if !put_byte(output, capacity, &output_length, u8(' ')) do return -2
		if !put_uint(output, capacity, &output_length, level) do return -2
		if !put_byte(output, capacity, &output_length, u8(9)) do return -2
		for i := 0; i < interval_count; i += 1 {
			left_num := start * denominator + span * positions[i]
			right_num := start * denominator + span * (positions[i] + 1)
			left := (left_num * SCALE + denominator / 2) / denominator
			right := (right_num * SCALE + denominator / 2) / denominator
			if !put_byte(output, capacity, &output_length, u8(9)) do return -2
			if !put_byte(output, capacity, &output_length, u8('[')) do return -2
			if !put_fixed(output, capacity, &output_length, left) do return -2
			if !put_byte(output, capacity, &output_length, u8(']')) do return -2
			if !put_byte(output, capacity, &output_length, u8(' ')) do return -2
			if !put_byte(output, capacity, &output_length, u8('-')) do return -2
			if !put_byte(output, capacity, &output_length, u8('-')) do return -2
			if !put_byte(output, capacity, &output_length, u8(' ')) do return -2
			if !put_byte(output, capacity, &output_length, u8('[')) do return -2
			if !put_fixed(output, capacity, &output_length, right) do return -2
			if !put_byte(output, capacity, &output_length, u8(']')) do return -2
		}
		if !put_byte(output, capacity, &output_length, u8('\n')) do return -2
		if level < max_level {
			if !put_byte(output, capacity, &output_length, u8('\n')) do return -2
			for i := 0; i < interval_count; i += 1 {
				next[2 * i] = positions[i] * 3
				next[2 * i + 1] = positions[i] * 3 + 2
			}
			interval_count *= 2
			for i := 0; i < interval_count; i += 1 { positions[i] = next[i] }
			denominator *= 3
		}
	}
	if output_length >= capacity do return -2
	output[output_length] = 0
	output_length += 1
	return i64(output_length)
}
