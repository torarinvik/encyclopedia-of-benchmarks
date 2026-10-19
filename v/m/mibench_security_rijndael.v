const key_bytes = 32
const block_bytes = 16
const input_bytes = 48

fn rijndael_gf_mul(left_value u8, right_value u8) u8 {
	mut left := left_value
	mut right := right_value
	mut result := u8(0)
	for right != 0 {
		if right & 1 != 0 { result ^= left }
		doubled := (u16(left) << 1) ^ if left & 0x80 != 0 { u16(0x1b) } else { u16(0) }
		left = u8(doubled)
		right >>= 1
	}
	return result
}

fn rijndael_gf_pow(value_value u8, exponent_value u32) u8 {
	mut value := value_value
	mut exponent := exponent_value
	mut result := u8(1)
	for exponent != 0 {
		if exponent & 1 != 0 { result = rijndael_gf_mul(result, value) }
		value = rijndael_gf_mul(value, value)
		exponent >>= 1
	}
	return result
}

fn rijndael_rotl8(value u8, amount int) u8 {
	return u8((u16(value) << amount) | (u16(value) >> (8 - amount)))
}

fn rijndael_make_sbox() [256]u8 {
	mut sbox := [256]u8{}
	for value in 0 .. 256 {
		inverse := if value == 0 { u8(0) } else { rijndael_gf_pow(u8(value), 254) }
		sbox[value] = inverse ^ rijndael_rotl8(inverse, 1) ^ rijndael_rotl8(inverse, 2) ^
			rijndael_rotl8(inverse, 3) ^ rijndael_rotl8(inverse, 4) ^ 0x63
	}
	return sbox
}

fn rijndael_encrypt_block(key [32]u8, block [16]u8) [16]u8 {
	sbox := rijndael_make_sbox()
	round_constants := [7]u8{1, 2, 4, 8, 16, 32, 64}
	mut round_keys := [240]u8{}
	for index in 0 .. key_bytes { round_keys[index] = key[index] }
	mut written := key_bytes
	for written < round_keys.len {
		word := written / 4
		mut temporary := [4]u8{round_keys[written - 4], round_keys[written - 3], round_keys[written - 2], round_keys[written - 1]}
		if word % 8 == 0 {
			first := temporary[0]
			temporary[0] = sbox[temporary[1]] ^ round_constants[word / 8 - 1]
			temporary[1] = sbox[temporary[2]]
			temporary[2] = sbox[temporary[3]]
			temporary[3] = sbox[first]
		} else if word % 8 == 4 {
			for index in 0 .. 4 { temporary[index] = sbox[temporary[index]] }
		}
		for index in 0 .. 4 {
			round_keys[written] = round_keys[written - key_bytes] ^ temporary[index]
			written++
		}
	}

	mut state := block
	for index in 0 .. block_bytes { state[index] ^= round_keys[index] }
	for round in 1 .. 14 {
		for index in 0 .. block_bytes { state[index] = sbox[state[index]] }
		previous := state
		for column in 0 .. 4 {
			for row in 0 .. 4 { state[row + 4 * column] = previous[row + 4 * ((column + row) % 4)] }
		}
		for column in 0 .. 4 {
			offset := 4 * column
			a, b, c, d := state[offset], state[offset + 1], state[offset + 2], state[offset + 3]
			total := a ^ b ^ c ^ d
			state[offset] = a ^ total ^ rijndael_gf_mul(a ^ b, 2)
			state[offset + 1] = b ^ total ^ rijndael_gf_mul(b ^ c, 2)
			state[offset + 2] = c ^ total ^ rijndael_gf_mul(c ^ d, 2)
			state[offset + 3] = d ^ total ^ rijndael_gf_mul(d ^ a, 2)
		}
		key_offset := round * block_bytes
		for index in 0 .. block_bytes { state[index] ^= round_keys[key_offset + index] }
	}
	for index in 0 .. block_bytes { state[index] = sbox[state[index]] }
	previous := state
	for column in 0 .. 4 {
		for row in 0 .. 4 { state[row + 4 * column] = previous[row + 4 * ((column + row) % 4)] }
	}
	for index in 0 .. block_bytes { state[index] ^= round_keys[224 + index] }
	return state
}

@[export: 'mibench_security_rijndael']
pub fn mibench_security_rijndael(input &i64, input_length usize, mut output &u8, output_capacity usize) i64 {
	unsafe {
		if input == nil || input_length != input_bytes { return -1 }
		for index in 0 .. input_bytes { if input[index] < 0 || input[index] > 255 { return -1 } }
		if output == nil || output_capacity < block_bytes { return -2 }
		mut key := [32]u8{}
		mut block := [16]u8{}
		for index in 0 .. key_bytes { key[index] = u8(input[index]) }
		for index in 0 .. block_bytes { block[index] = u8(input[key_bytes + index]) }
		ciphertext := rijndael_encrypt_block(key, block)
		for index in 0 .. block_bytes { output[index] = ciphertext[index] }
		return i64(block_bytes)
	}
}
