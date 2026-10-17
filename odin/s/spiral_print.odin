package spiral_print

import "core:c"

MAX_CELLS :: 16 * 16
MAX_INPUT_LENGTH :: 259

write_i64_le :: proc "contextless" (output: [^]u8, offset: int, value: i32) {
	bits := transmute(u64)i64(value)
	for byte := 0; byte < 8; byte += 1 {
		output[offset + byte] = u8(bits & 0xff)
		bits >>= 8
	}
}

spiral_print :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > c.size_t(MAX_INPUT_LENGTH) do return -1
	if input[0] < 1 || input[0] > 16 || input[1] < 2 || input[1] > 16 do return -1
	rows, columns := int(input[0]), int(input[1])
	cell_count := rows * columns
	if int(length) != 2 + cell_count do return -1
	matrix: [MAX_CELLS]i32
	for index := 0; index < cell_count; index += 1 {
		value := input[2 + index]
		if value < -2147483648 || value > 2147483647 do return -1
		matrix[index] = i32(value)
	}
	required := 8 * cell_count
	if output == nil || capacity < c.size_t(required) do return -2

	order: [MAX_CELLS]i32
	written := 0
	top, bottom, left, right := 0, rows - 1, 0, columns - 1
	for top <= bottom && left <= right {
		for column := left; column <= right; column += 1 { order[written] = matrix[top*columns+column]; written += 1 }
		top += 1
		for row := top; row <= bottom; row += 1 { order[written] = matrix[row*columns+right]; written += 1 }
		right -= 1
		if top <= bottom && left <= right {
			for column := right; column >= left; column -= 1 { order[written] = matrix[bottom*columns+column]; written += 1 }
			bottom -= 1
		}
		if top <= bottom && left <= right {
			for row := bottom; row >= top; row -= 1 { order[written] = matrix[row*columns+left]; written += 1 }
			left += 1
		}
	}
	for index := 0; index < written; index += 1 { write_i64_le(output, index*8, order[index]) }
	return i64(required)
}
