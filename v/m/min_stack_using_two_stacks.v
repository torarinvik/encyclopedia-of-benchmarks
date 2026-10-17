const max_operations = 256
const max_input_values = 513
const max_output_bytes = 6152

fn write_i64_le(output []u8, offset int, value i64) {
	mut bits := u64(value)
	for byte in 0 .. 8 {
		output[offset + byte] = u8(bits & 255)
		bits >>= 8
	}
}

@[export: 'min_stack_using_two_stacks']
pub fn min_stack_using_two_stacks(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 1 || length > max_input_values { return -1 }
	unsafe {
		count_value := input[0]
		if count_value < 0 || count_value > max_operations { return -1 }
		count := int(count_value)

		mut opcodes := [max_operations]i64{}
		mut operands := [max_operations]i64{}
		mut position := 1
		mut event_count := 0
		for index in 0 .. count {
			if position >= int(length) { return -1 }
			opcode := input[position]
			position++
			mut operand := i64(0)
			if opcode == 0 {
				if position >= int(length) { return -1 }
				operand = input[position]
				position++
				if operand < -2_147_483_648 || operand > 2_147_483_647 { return -1 }
			} else if opcode == 1 || opcode == 2 || opcode == 3 {
				event_count++
			} else {
				return -1
			}
			opcodes[index] = opcode
			operands[index] = operand
		}
		if position != int(length) { return -1 }

		needed := (1 + 3 * event_count) * 8
		if output == nil || capacity < usize(needed) { return -2 }

		mut buffer := [max_output_bytes]u8{}
		write_i64_le(mut buffer, 0, i64(event_count))
		mut stack := [max_operations]i64{}
		mut minima := [max_operations]i64{}
		mut depth := 0
		mut minimum_depth := 0
		mut record := 1
		for index in 0 .. count {
			opcode := opcodes[index]
			if opcode == 0 {
				value := operands[index]
				stack[depth] = value
				depth++
				if minimum_depth == 0 || value <= minima[minimum_depth - 1] {
					minima[minimum_depth] = value
					minimum_depth++
				}
			} else if opcode == 1 {
				mut exception_flag := i64(0)
				if depth == 0 {
					exception_flag = 1
				} else {
					depth--
					if stack[depth] == minima[minimum_depth - 1] { minimum_depth-- }
				}
				write_i64_le(mut buffer, record * 8, 1)
				write_i64_le(mut buffer, (record + 1) * 8, exception_flag)
				write_i64_le(mut buffer, (record + 2) * 8, 0)
				record += 3
			} else {
				mut exception_flag := i64(0)
				mut value := i64(0)
				if depth == 0 {
					exception_flag = 1
				} else if opcode == 2 {
					value = stack[depth - 1]
				} else {
					value = minima[minimum_depth - 1]
				}
				write_i64_le(mut buffer, record * 8, opcode)
				write_i64_le(mut buffer, (record + 1) * 8, exception_flag)
				write_i64_le(mut buffer, (record + 2) * 8, value)
				record += 3
			}
		}
		for index in 0 .. needed { output[index] = buffer[index] }
		return i64(needed)
	}
}
