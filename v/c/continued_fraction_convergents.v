module continued_fraction_convergents

fn store_i64_le(mut output &u8, offset int, value i64) {
	bits := u64(value)
	unsafe {
		for byte in 0 .. 8 {
			output[offset + byte] = u8((bits >> u64(8 * byte)) & 255)
		}
	}
}

@[export: 'continued_fraction_convergents']
pub fn continued_fraction_convergents(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > 18 { return -1 }
		count_value := input[0]
		if count_value < 1 || count_value > 16 || input[1] < -1000 || input[1] > 1000 { return -1 }
		count := int(count_value)
		if int(length) != count + 1 { return -1 }
		for index in 2 .. int(length) {
			if input[index] < 1 || input[index] > 8 { return -1 }
		}
		required := usize(16 * count)
		if output == nil || capacity < required { return -2 }

		mut p_two_back := i64(0)
		mut p_one_back := i64(1)
		mut q_two_back := i64(1)
		mut q_one_back := i64(0)
		for index in 0 .. count {
			p := input[index+1]*p_one_back + p_two_back
			q := input[index+1]*q_one_back + q_two_back
			store_i64_le(mut output, 16*index, p)
			store_i64_le(mut output, 16*index+8, q)
			p_two_back = p_one_back; p_one_back = p
			q_two_back = q_one_back; q_one_back = q
		}
		return i64(required)
	}
}
