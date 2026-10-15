package shortest_coprime_segment

import "core:c"

MAX_LENGTH :: 128

gcd_positive :: proc "contextless" (a, b: i64) -> i64 {
	left, right := a, b
	for right != 0 {
		remainder := left % right
		left, right = right, remainder
	}
	return left
}

push :: proc "contextless" (value: i64, items, aggregates: [^]i64, length: ^c.size_t) {
	items[length^] = value
	aggregates[length^] = if length^ == 0 do value else gcd_positive(aggregates[length^ - 1], value)
	length^ += 1
}

@(export)
shortest_coprime_segment :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if length > MAX_LENGTH || (length != 0 && input == nil) do return -1
	for i := 0; i < int(length); i += 1 { if input[i] < 1 || input[i] > 1000 do return -1 }
	front: [MAX_LENGTH]i64
	front_gcd: [MAX_LENGTH]i64
	back: [MAX_LENGTH]i64
	back_gcd: [MAX_LENGTH]i64
	front_length, back_length := c.size_t(0), c.size_t(0)
	left, best_start, best_length := c.size_t(0), c.size_t(0), length + 1
	for right := c.size_t(0); right < length; right += 1 {
		push(input[right], &back[0], &back_gcd[0], &back_length)
		window_gcd := gcd_positive(
			if front_length > 0 do front_gcd[front_length - 1] else 0,
			if back_length > 0 do back_gcd[back_length - 1] else 0)
		for window_gcd == 1 {
			current_length := right - left + 1
			if current_length < best_length { best_length, best_start = current_length, left }
			if front_length == 0 {
				for back_length > 0 {
					back_length -= 1
					push(back[back_length], &front[0], &front_gcd[0], &front_length)
				}
			}
			front_length -= 1
			left += 1
			window_gcd = gcd_positive(
				if front_length > 0 do front_gcd[front_length - 1] else 0,
				if back_length > 0 do back_gcd[back_length - 1] else 0)
		}
	}
	if best_length > length do return 0
	byte_count := best_length * 8
	if output == nil || output_capacity < byte_count do return -2
	for i := c.size_t(0); i < best_length; i += 1 {
		bits := u64(input[best_start + i])
		for byte := c.size_t(0); byte < 8; byte += 1 { output[8 * i + byte] = u8((bits >> (8 * byte)) & 255) }
	}
	return i64(byte_count)
}
