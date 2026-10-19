package mibench_security_rijndael

import "core:c"

KEY_BYTES :: 32
BLOCK_BYTES :: 16
INPUT_BYTES :: 48

gf_mul :: proc "contextless" (left_value, right_value: u8) -> u8 {
	left, right: u8 = left_value, right_value
	result: u8 = 0
	for right != 0 {
		if (right & 1) != 0 { result ^= left }
		doubled := (u16(left) << 1) ^ (if (left & 0x80) != 0 do u16(0x1b) else do u16(0))
		left = u8(doubled)
		right >>= 1
	}
	return result
}

gf_pow :: proc "contextless" (value_value: u8, exponent_value: u32) -> u8 {
	value, exponent := value_value, exponent_value
	result: u8 = 1
	for exponent != 0 {
		if (exponent & 1) != 0 { result = gf_mul(result, value) }
		value = gf_mul(value, value)
		exponent >>= 1
	}
	return result
}

rotl8 :: proc "contextless" (value: u8, amount: u32) -> u8 {
	return u8((u16(value) << amount) | (u16(value) >> (8 - amount)))
}

make_sbox :: proc "contextless" () -> [256]u8 {
	mut sbox: [256]u8
	for value := 0; value < 256; value += 1 {
		inverse := if value == 0 do u8(0) else do gf_pow(u8(value), 254)
		sbox[value] = inverse ^ rotl8(inverse, 1) ^ rotl8(inverse, 2) ^ rotl8(inverse, 3) ^ rotl8(inverse, 4) ^ 0x63
	}
	return sbox
}

encrypt_block :: proc "contextless" (key, block: [^]u8, output: [^]u8) {
	sbox := make_sbox()
	round_constants := [7]u8{1, 2, 4, 8, 16, 32, 64}
	mut round_keys: [240]u8
	for i := 0; i < KEY_BYTES; i += 1 { round_keys[i] = key[i] }
	mut written := KEY_BYTES
	for written < 240 {
		word := written / 4
		mut temporary := [4]u8{round_keys[written-4], round_keys[written-3], round_keys[written-2], round_keys[written-1]}
		if word % 8 == 0 {
			first := temporary[0]
			temporary[0] = sbox[temporary[1]] ^ round_constants[word / 8 - 1]
			temporary[1] = sbox[temporary[2]]
			temporary[2] = sbox[temporary[3]]
			temporary[3] = sbox[first]
		} else if word % 8 == 4 {
			for i := 0; i < 4; i += 1 { temporary[i] = sbox[temporary[i]] }
		}
		for i := 0; i < 4; i += 1 {
			round_keys[written] = round_keys[written-KEY_BYTES] ^ temporary[i]
			written += 1
		}
	}

	mut state: [16]u8
	for i := 0; i < BLOCK_BYTES; i += 1 { state[i] = block[i] ^ round_keys[i] }
	for round := 1; round < 14; round += 1 {
		for i := 0; i < BLOCK_BYTES; i += 1 { state[i] = sbox[state[i]] }
		previous := state
		for column := 0; column < 4; column += 1 {
			for row := 0; row < 4; row += 1 { state[row+4*column] = previous[row+4*((column+row)%4)] }
		}
		for column := 0; column < 4; column += 1 {
			offset := 4 * column
			a, b, c, d := state[offset], state[offset+1], state[offset+2], state[offset+3]
			total := a ^ b ^ c ^ d
			state[offset] = a ^ total ^ gf_mul(a^b, 2)
			state[offset+1] = b ^ total ^ gf_mul(b^c, 2)
			state[offset+2] = c ^ total ^ gf_mul(c^d, 2)
			state[offset+3] = d ^ total ^ gf_mul(d^a, 2)
		}
		key_offset := round * BLOCK_BYTES
		for i := 0; i < BLOCK_BYTES; i += 1 { state[i] ^= round_keys[key_offset+i] }
	}
	for i := 0; i < BLOCK_BYTES; i += 1 { state[i] = sbox[state[i]] }
	previous := state
	for column := 0; column < 4; column += 1 {
		for row := 0; row < 4; row += 1 { state[row+4*column] = previous[row+4*((column+row)%4)] }
	}
	for i := 0; i < BLOCK_BYTES; i += 1 { output[i] = state[i] ^ round_keys[224+i] }
}

@(export)
mibench_security_rijndael :: proc "c" (input: [^]i64, input_length: c.size_t,
	output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || input_length != c.size_t(INPUT_BYTES) do return -1
	for i := 0; i < INPUT_BYTES; i += 1 { if input[i] < 0 || input[i] > 255 do return -1 }
	if output == nil || output_capacity < c.size_t(BLOCK_BYTES) do return -2
	mut key: [KEY_BYTES]u8
	mut block: [BLOCK_BYTES]u8
	mut ciphertext: [BLOCK_BYTES]u8
	for i := 0; i < KEY_BYTES; i += 1 { key[i] = u8(input[i]) }
	for i := 0; i < BLOCK_BYTES; i += 1 { block[i] = u8(input[KEY_BYTES+i]) }
	encrypt_block(&key[0], &block[0], &ciphertext[0])
	for i := 0; i < BLOCK_BYTES; i += 1 { output[i] = ciphertext[i] }
	return i64(BLOCK_BYTES)
}
