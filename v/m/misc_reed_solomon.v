// Derived from the Reed-Solomon program by Simon Rockliff, 26 June 1991.
// See benchmarks/m/misc_reed_solomon/LICENSE.txt for the complete permission notice.
module misc_reed_solomon

const message_bytes = 188
const parity_bytes = 16
const codeword_bytes = 204
const full_bytes = 255

fn make_tables(mut alpha &i32, mut index_of &i32) {
	unsafe {
		polynomial := [i32(1), 0, 1, 1, 1, 0, 0, 0]
		for i in 0 .. 256 { index_of[i] = -1 }
		mut mask := i32(1)
		mut alpha_8 := i32(0)
		for i in 0 .. 8 {
			alpha[i] = mask
			index_of[int(alpha[i])] = i32(i)
			if polynomial[i] != 0 { alpha_8 ^= mask }
			mask <<= 1
		}
		alpha[8] = alpha_8
		index_of[int(alpha_8)] = 8
		mask >>= 1
		for i in 9 .. full_bytes {
			if alpha[i - 1] >= mask { alpha[i] = alpha_8 ^ ((alpha[i - 1] ^ mask) << 1) }
			else { alpha[i] = alpha[i - 1] << 1 }
			index_of[int(alpha[i])] = i32(i)
		}
		index_of[0] = -1
	}
}

fn make_generator(alpha &i32, index_of &i32, mut generator &i32) {
	unsafe {
		generator[0] = 2
		generator[1] = 1
		for root in 2 .. parity_bytes + 1 {
			generator[root] = 1
			mut index := root - 1
			for index > 0 {
				if generator[index] != 0 {
					generator[index] = generator[index - 1] ^ alpha[int((index_of[int(generator[index])] + i32(root)) % i32(full_bytes))]
				} else {
					generator[index] = generator[index - 1]
				}
				index--
			}
			generator[0] = alpha[int((index_of[int(generator[0])] + i32(root)) % i32(full_bytes))]
		}
		for index in 0 .. parity_bytes + 1 { generator[index] = index_of[int(generator[index])] }
	}
}

fn encode(values &i64, alpha &i32, index_of &i32, generator &i32, mut codeword &i32) {
	unsafe {
		mut data := [239]i32{}
		mut parity := [parity_bytes]i32{}
		for index in 0 .. message_bytes { data[51 + index] = i32(values[index]) }
		mut data_index := 238
		for data_index >= 0 {
			feedback := index_of[int(data[data_index] ^ parity[15])]
			if feedback != -1 {
				mut parity_index := 15
				for parity_index > 0 {
					if generator[parity_index] != -1 {
						parity[parity_index] = parity[parity_index - 1] ^ alpha[int((generator[parity_index] + feedback) % i32(full_bytes))]
					} else {
						parity[parity_index] = parity[parity_index - 1]
					}
					parity_index--
				}
				parity[0] = alpha[int((generator[0] + feedback) % i32(full_bytes))]
			} else {
				mut parity_index := 15
				for parity_index > 0 {
					parity[parity_index] = parity[parity_index - 1]
					parity_index--
				}
				parity[0] = 0
			}
			data_index--
		}
		for index in 0 .. message_bytes { codeword[index] = i32(values[index]) }
		for index in 0 .. parity_bytes { codeword[message_bytes + index] = parity[index] }
	}
}

fn multiply(left i32, right i32, alpha &i32, index_of &i32) i32 {
	unsafe {
		if left == 0 || right == 0 { return 0 }
		mut exponent := index_of[int(left)] + index_of[int(right)]
		if exponent >= full_bytes { exponent -= i32(full_bytes) }
		return alpha[int(exponent)]
	}
}

fn divide(left i32, right i32, alpha &i32, index_of &i32) i32 {
	unsafe {
		if left == 0 { return 0 }
		mut exponent := index_of[int(left)] - index_of[int(right)]
		if exponent < 0 { exponent += i32(full_bytes) }
		return alpha[int(exponent)]
	}
}

fn correct_one(mut codeword &i32, expected_position int, alpha &i32, index_of &i32) bool {
	unsafe {
		mut syndrome_1 := i32(0)
		mut syndrome_2 := i32(0)
		for full_position in 0 .. full_bytes {
			mut symbol := i32(0)
			if full_position < parity_bytes { symbol = codeword[message_bytes + full_position] }
			else if full_position >= 67 { symbol = codeword[full_position - 67] }
			syndrome_1 ^= multiply(symbol, alpha[full_position % full_bytes], alpha, index_of)
			syndrome_2 ^= multiply(symbol, alpha[(2 * full_position) % full_bytes], alpha, index_of)
		}
		if syndrome_1 == 0 && syndrome_2 == 0 { return true }
		if syndrome_1 == 0 { return false }
		location := divide(syndrome_2, syndrome_1, alpha, index_of)
		mut full_position := -1
		for index in 0 .. full_bytes {
			if alpha[index] == location { full_position = index; break }
		}
		if full_position < 0 { return false }
		mut transmitted_position := -1
		if full_position < parity_bytes { transmitted_position = message_bytes + full_position }
		else if full_position >= 67 { transmitted_position = full_position - 67 }
		if transmitted_position < 0 || transmitted_position != expected_position { return false }
		magnitude := divide(syndrome_1, alpha[full_position], alpha, index_of)
		codeword[transmitted_position] ^= magnitude
		return true
	}
}

@[export: 'misc_reed_solomon']
pub fn misc_reed_solomon(values &i64, length usize, mut output &u8, output_capacity usize) i64 {
	unsafe {
		if values == nil || (length != message_bytes + 1 && length != message_bytes + 3) { return -1 }
		for index in 0 .. message_bytes {
			if values[index] < 0 || values[index] > 255 { return -1 }
		}
		error_count := values[message_bytes]
		if (error_count == 0 && length != message_bytes + 1) ||
			(error_count == 1 && length != message_bytes + 3) ||
			(error_count != 0 && error_count != 1) { return -1 }
		mut error_position := -1
		if error_count == 1 {
			if values[189] < 0 || values[189] >= codeword_bytes || values[190] < 0 || values[190] > 255 { return -1 }
			error_position = int(values[189])
		}
		if output == nil || output_capacity < codeword_bytes { return -2 }

		mut alpha := [full_bytes]i32{}
		mut index_of := [256]i32{}
		mut generator := [parity_bytes + 1]i32{}
		mut staged := [codeword_bytes]i32{}
		make_tables(mut alpha[0], mut index_of[0])
		make_generator(alpha[0], index_of[0], mut generator[0])
		encode(values, alpha[0], index_of[0], generator[0], mut staged[0])
		if error_count == 1 { staged[error_position] = i32(values[190]) }
		if !correct_one(mut staged[0], error_position, alpha[0], index_of[0]) { return -1 }
		for index in 0 .. codeword_bytes { output[index] = u8(staged[index]) }
		return i64(codeword_bytes)
	}
}
