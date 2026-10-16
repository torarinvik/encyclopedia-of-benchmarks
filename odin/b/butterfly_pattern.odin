package butterfly_pattern

import "core:c"

write_run :: proc "contextless" (output: [^]u8, position_input: int, byte: u8, count: int) -> int {
	position := position_input
	for index := 0; index < count; index += 1 {
		output[position] = byte
		position += 1
	}
	return position
}

@(export)
butterfly_pattern :: proc "c" (n: i64, output: [^]u8, capacity: c.size_t) -> i64 {
	if n < 1 || n > 45 do return -1
	side := int(n)
	width := 2 * side - 1
	required := width * width + 2 * side - 2
	if output == nil || capacity < c.size_t(required) do return -2

	position := 0
	for count := 1; count < side; count += 1 {
		if position != 0 { output[position] = 10; position += 1 }
		position = write_run(output, position, u8('*'), count)
		position = write_run(output, position, u8(' '), 2 * (side - count) - 1)
		position = write_run(output, position, u8('*'), count)
	}
	if position != 0 { output[position] = 10; position += 1 }
	position = write_run(output, position, u8('*'), width)
	count := side - 1
	for count > 0 {
		output[position] = 10; position += 1
		position = write_run(output, position, u8('*'), count)
		position = write_run(output, position, u8(' '), 2 * (side - count) - 1)
		position = write_run(output, position, u8('*'), count)
		count -= 1
	}
	return i64(position)
}
