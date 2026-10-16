module single_bit_manipulation_operations

@[export: 'single_bit_manipulation_operations']
pub fn single_bit_manipulation_operations(input &i64, length usize) i64 {
	if unsafe { input == nil } || length != 3 { return -1 }
	unsafe {
		opcode, number, position := input[0], input[1], input[2]
		if opcode < 0 || opcode > 5 || number < -2147483648 || number > 2147483647 { return -1 }
		if opcode == 5 {
			if position != -1 { return -1 }
			return number & (number - 1)
		}
		if position < 0 || position > 31 { return -1 }
		mask := i64(1) << int(position)
		match opcode {
			0 { return number | mask }
			1 { return number & ~mask }
			2 { return number ^ mask }
			3 { return i64((u64(number) >> u64(position)) & 1) }
			4 { return if (number & mask) != 0 { i64(1) } else { i64(0) } }
			else { return -1 }
		}
	}
}
