module prefix_sum_of_binomial_coefficient

const prefix_modulus = i64(998244353)

@[export: 'prefix_sum_of_binomial_coefficient']
pub fn prefix_sum_of_binomial_coefficient(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if input == nil || length < 3 || length > 34 { return -1 }
	unsafe {
		count_value := input[0]
		if count_value < 1 || count_value > 16 { return -1 }
		count := int(count_value)
		if int(length) != 1 + 2 * count { return -1 }
		mut ns := [16]i64{}
		mut ks := [16]i64{}
		for query in 0 .. count {
			ns[query] = input[1 + 2 * query]
			ks[query] = input[2 + 2 * query]
			if ns[query] < 0 || ns[query] > 128 || ks[query] < 0 || ks[query] > ns[query] { return -1 }
		}
		output_length := 4 * count
		if output == nil || capacity < output_length { return -2 }

		mut inverse := [129]i64{}
		inverse[1] = 1
		for value in 2 .. 129 {
			v := i64(value)
			inverse[value] = prefix_modulus - (prefix_modulus / v) * inverse[int(prefix_modulus % v)] % prefix_modulus
		}
		for query in 0 .. count {
			mut coefficient := i64(1)
			mut prefix := i64(1)
			for index in 0 .. int(ks[query]) {
				coefficient = coefficient * (ns[query] - i64(index)) % prefix_modulus
				coefficient = coefficient * inverse[index + 1] % prefix_modulus
				prefix = (prefix + coefficient) % prefix_modulus
			}
			offset := 4 * query
			output[offset] = u8(prefix % 256)
			output[offset + 1] = u8((prefix / 256) % 256)
			output[offset + 2] = u8((prefix / 65_536) % 256)
			output[offset + 3] = u8(prefix / 16_777_216)
		}
		return i64(output_length)
	}
}
