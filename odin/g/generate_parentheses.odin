package generate_parentheses

import "core:c"

walk :: proc(pairs, opened, closed: int, buffer, output: []u8, cursor: int) -> int {
	position := opened + closed
	if position == 2*pairs {
		next := cursor
		for index := 0; index < position; index += 1 {
			output[next] = buffer[index]
			next += 1
		}
		return next
	}
	next := cursor
	if opened < pairs {
		buffer[position] = u8('(')
		next = walk(pairs, opened + 1, closed, buffer, output, next)
	}
	if closed < opened {
		buffer[position] = u8(')')
		next = walk(pairs, opened, closed + 1, buffer, output, next)
	}
	return next
}

@(export)
generate_parentheses :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length != 1 || input[0] < 1 || input[0] > 6 do return -1
	pairs := int(input[0])
	requireds := [7]int{0, 2, 8, 30, 112, 420, 1584}
	required := requireds[pairs]
	if capacity < c.size_t(required) || output == nil do return -2
	buffer: [12]u8
	bytes := make([]u8, required)
	cursor := walk(pairs, 0, 0, buffer[:], bytes, 0)
	for index := 0; index < required; index += 1 do output[index] = bytes[index]
	return i64(cursor)
}
