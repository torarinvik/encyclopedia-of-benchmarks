module binary_twos_complement

@[export: 'twos_complement']
pub fn twos_complement(value i64, output &u8, output_capacity usize) i64 {
	if value > 0 { return -1 }
	if value == 0 {
		if output_capacity < 3 { return -2 }
		unsafe { output[0] = 48; output[1] = 98; output[2] = 48 }
		return 3
	}
	magnitude := u64(-(value + 1)) + u64(1)
	mut bit_length := usize(0)
	mut remaining := magnitude
	for remaining > 0 {
		bit_length++
		remaining /= u64(2)
	}
	mut suffix := magnitude
	if bit_length < 64 {
		mut power := u64(1)
		mut exponent := usize(0)
		for exponent < bit_length {
			power *= u64(2)
			exponent++
		}
		suffix = power - magnitude
	}
	mut bits := [64]u8{}
	mut bit_count := usize(0)
	remaining = suffix
	for remaining > 0 {
		bits[bit_count] = u8(48) + u8(remaining % u64(2))
		bit_count++
		remaining /= u64(2)
	}
	needed := bit_length + 3
	if output_capacity < needed { return -2 }
	mut position := usize(0)
	unsafe {
		output[position] = 48; position++
		output[position] = 98; position++
		output[position] = 49; position++
		zero_count := bit_length - bit_count
		for mut zero := usize(0); zero < zero_count; zero++ { output[position] = 48; position++ }
		for bit_count > 0 {
			bit_count--
			output[position] = bits[bit_count]
			position++
		}
	}
	return i64(position)
}
