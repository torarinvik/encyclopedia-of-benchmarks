fn rotate_right(value u64, count int) u64 {
	return (value >> count) | (value << (64 - count))
}

fn permute(mut state []u64, rounds int) {
	mut constants := [12]u64{init: 0}
	constants[0] = 0xf0; constants[1] = 0xe1; constants[2] = 0xd2; constants[3] = 0xc3
	constants[4] = 0xb4; constants[5] = 0xa5; constants[6] = 0x96; constants[7] = 0x87
	constants[8] = 0x78; constants[9] = 0x69; constants[10] = 0x5a; constants[11] = 0x4b
	first := if rounds == 12 { 0 } else { 4 }
	for round in first .. 12 {
		x0, x1, x2, x3, x4 := state[0], state[1], state[2], state[3], state[4]
		c := constants[round]
		t0 := x0 ^ x1 ^ x2 ^ x3 ^ c ^ (x1 & (x0 ^ x2 ^ x4 ^ c))
		t1 := x0 ^ x2 ^ x3 ^ x4 ^ c ^ ((x1 ^ x2 ^ c) & (x1 ^ x3))
		t2 := x1 ^ x2 ^ x4 ^ c ^ (x3 & x4)
		t3 := x0 ^ x1 ^ x2 ^ c ^ (~x0 & (x3 ^ x4))
		t4 := x1 ^ x3 ^ x4 ^ ((x0 ^ x4) & x1)
		state[0] = t0 ^ rotate_right(t0, 19) ^ rotate_right(t0, 28)
		state[1] = t1 ^ rotate_right(t1, 39) ^ rotate_right(t1, 61)
		state[2] = ~(t2 ^ rotate_right(t2, 1) ^ rotate_right(t2, 6))
		state[3] = t3 ^ rotate_right(t3, 10) ^ rotate_right(t3, 17)
		state[4] = t4 ^ rotate_right(t4, 7) ^ rotate_right(t4, 41)
	}
}

fn write_u64_be(mut output &u8, offset int, value u64) {
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8(value >> (56 - byte * 8)) }
	}
}

@[export: 'ascon_digest']
pub fn ascon_digest(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if length < 2 || isnil(input) { return -1 }
	variant := unsafe { input[0] }
	message_length_value := unsafe { input[1] }
	if (variant != 0 && variant != 1) || message_length_value < 0 || message_length_value > 4096 ||
		length != usize(message_length_value + 2) { return -1 }
	message_length := int(message_length_value)
	for index in 0 .. message_length {
		value := unsafe { input[index + 2] }
		if value < 0 || value > 255 { return -1 }
	}

	mut state := []u64{len: 5, init: 0}
	if variant == 0 {
		state[0] = 0xee9398aadb67f03d
		state[1] = 0x8bb21831c60f1002
		state[2] = 0xb48a92db98d5da62
		state[3] = 0x43189921b8f8e3e8
		state[4] = 0x348fa5c9d525e140
	} else {
		state[0] = 0x01470194fc6528a6
		state[1] = 0x738ec38ac0adffa7
		state[2] = 0x2ec8e3296c76384c
		state[3] = 0xd6f6a54d7f52377d
		state[4] = 0xa13c42a223be8d87
	}
	rounds := if variant == 0 { 12 } else { 8 }
	complete_length := message_length - message_length % 8
	for offset := 0; offset < complete_length; offset += 8 {
		mut word := u64(0)
		for byte in 0 .. 8 { word = (word << 8) | u64(unsafe { input[offset + byte + 2] }) }
		state[0] ^= word
		permute(mut state, rounds)
	}
	tail_length := message_length - complete_length
	mut final_word := u64(0x80) << (56 - tail_length * 8)
	for byte in 0 .. tail_length {
		final_word |= u64(unsafe { input[complete_length + byte + 2] }) << (56 - byte * 8)
	}
	state[0] ^= final_word
	permute(mut state, 12)

	if capacity < 32 || isnil(output) { return -2 }
	for block in 0 .. 4 {
		write_u64_be(mut output, block * 8, state[0])
		if block != 3 { permute(mut state, rounds) }
	}
	return 32
}
