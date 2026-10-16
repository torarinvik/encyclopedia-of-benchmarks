module butterfly_pattern

fn write_run(output &u8, position_input int, byte u8, count int) int {
	mut position := position_input
	unsafe {
		for _ in 0 .. count {
			output[position] = byte
			position++
		}
	}
	return position
}

@[export: 'butterfly_pattern']
pub fn butterfly_pattern(n i64, output &u8, capacity usize) i64 {
	if n < 1 || n > 45 { return -1 }
	side := int(n)
	width := 2 * side - 1
	required := width * width + 2 * side - 2
	if unsafe { output == nil } || capacity < usize(required) { return -2 }

	mut position := 0
	for count in 1 .. side {
		if position != 0 {
			unsafe { output[position] = 10 }
			position++
		}
		position = write_run(output, position, u8(`*`), count)
		position = write_run(output, position, u8(` `), 2 * (side - count) - 1)
		position = write_run(output, position, u8(`*`), count)
	}
	if position != 0 {
		unsafe { output[position] = 10 }
		position++
	}
	position = write_run(output, position, u8(`*`), width)
	mut count := side - 1
	for count > 0 {
		unsafe { output[position] = 10 }
		position++
		position = write_run(output, position, u8(`*`), count)
		position = write_run(output, position, u8(` `), 2 * (side - count) - 1)
		position = write_run(output, position, u8(`*`), count)
		count--
	}
	return i64(position)
}
