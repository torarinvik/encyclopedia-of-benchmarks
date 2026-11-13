module prime_modulus_inverse_table

@[export: 'prime_modulus_inverse_table']
pub fn prime_modulus_inverse_table(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if input == nil || length < 1 || length > 34 { return -1 }
	unsafe {
		count_value := input[0]
		if count_value < 0 || count_value > 32 { return -1 }
		count := int(count_value)
		if int(length) != count + 1 { return -1 }
		mut maximum := 0
		for i in 0 .. count {
			operand := input[i + 1]
			if operand < 1 || operand > 256 { return -1 }
			if int(operand) > maximum { maximum = int(operand) }
		}
		if count == 0 { return 0 }
		bytes := 4 * count
		if output == nil || capacity < usize(bytes) { return -2 }
		modulus := i64(1000000007)
		mut inverse := [257]i64{}
		inverse[1] = 1
		for i in 2 .. maximum + 1 {
			value := i64(i)
			inverse[i] = modulus - (modulus / value) * inverse[int(modulus % value)] % modulus
		}
		for i in 0 .. count {
			value := inverse[int(input[i + 1])]
			output[4*i] = u8(value % 256)
			output[4*i+1] = u8((value / 256) % 256)
			output[4*i+2] = u8((value / 65536) % 256)
			output[4*i+3] = u8(value / 16777216)
		}
		return i64(bytes)
	}
}
