module salsa

const salsa_word_count = 16
const salsa_output_bytes = 64

fn add32(left u32, right u32) u32 {
	return left +% right
}

fn rotate_left(value u32, amount u32) u32 {
	return (value << amount) | (value >> (32 - amount))
}

fn quarter_round(mut state []u32, first int, second int, third int, fourth int) {
	state[second] ^= rotate_left(add32(state[first], state[fourth]), 7)
	state[third] ^= rotate_left(add32(state[second], state[first]), 9)
	state[fourth] ^= rotate_left(add32(state[third], state[second]), 13)
	state[first] ^= rotate_left(add32(state[fourth], state[third]), 18)
}

fn store_u32_le(output &u8, offset int, value u32) {
	unsafe {
		for byte in 0 .. 4 {
			output[offset + byte] = u8((value >> u32(byte * 8)) & 255)
		}
	}
}

// Reproduce the pinned 16-word Salsa core variant; this is not a stream cipher.
@[export: 'salsa']
pub fn salsa(input &i32, length usize, output &u8, output_capacity usize) i64 {
	unsafe {
		if input == nil || length != salsa_word_count { return -1 }
		mut original := []u32{len: salsa_word_count}
		for index in 0 .. salsa_word_count {
			original[index] = u32(input[index])
		}
		if output == nil || output_capacity < salsa_output_bytes { return -2 }

		mut state := []u32{len: salsa_word_count}
		for index in 0 .. salsa_word_count { state[index] = original[index] }
		for _ in 0 .. 10 {
			quarter_round(mut state, 0, 4, 8, 12)
			quarter_round(mut state, 5, 9, 13, 1)
			quarter_round(mut state, 10, 14, 2, 6)
			quarter_round(mut state, 15, 3, 7, 11)
			quarter_round(mut state, 0, 1, 2, 3)
			quarter_round(mut state, 5, 6, 7, 4)
			quarter_round(mut state, 10, 11, 8, 9)
			quarter_round(mut state, 15, 12, 13, 14)
		}
		for index in 0 .. salsa_word_count {
			state[index] = add32(state[index], original[index])
			store_u32_le(output, index * 4, state[index])
		}
		return salsa_output_bytes
	}
}
