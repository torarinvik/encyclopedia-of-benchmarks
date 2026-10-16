package ascon_digest

import "core:c"

MAX_MESSAGE_BYTES :: 4096

rotate_right :: proc "contextless" (value: u64, count: u64) -> u64 {
	return (value >> count) | (value << (64 - count))
}

permute :: proc "contextless" (state: [^]u64, rounds: int) {
	constants := [12]u64{0xf0, 0xe1, 0xd2, 0xc3, 0xb4, 0xa5, 0x96, 0x87, 0x78, 0x69, 0x5a, 0x4b}
	first := 4
	if rounds == 12 { first = 0 }
	for round := first; round < 12; round += 1 {
		x0, x1, x2, x3, x4 := state[0], state[1], state[2], state[3], state[4]
		c := constants[round]
		t0 := x0 ~ x1 ~ x2 ~ x3 ~ c ~ (x1 & (x0 ~ x2 ~ x4 ~ c))
		t1 := x0 ~ x2 ~ x3 ~ x4 ~ c ~ ((x1 ~ x2 ~ c) & (x1 ~ x3))
		t2 := x1 ~ x2 ~ x4 ~ c ~ (x3 & x4)
		t3 := x0 ~ x1 ~ x2 ~ c ~ (~x0 & (x3 ~ x4))
		t4 := x1 ~ x3 ~ x4 ~ ((x0 ~ x4) & x1)
		state[0] = t0 ~ rotate_right(t0, 19) ~ rotate_right(t0, 28)
		state[1] = t1 ~ rotate_right(t1, 39) ~ rotate_right(t1, 61)
		state[2] = ~(t2 ~ rotate_right(t2, 1) ~ rotate_right(t2, 6))
		state[3] = t3 ~ rotate_right(t3, 10) ~ rotate_right(t3, 17)
		state[4] = t4 ~ rotate_right(t4, 7) ~ rotate_right(t4, 41)
	}
}

write_u64_be :: proc "contextless" (output: [^]u8, offset: int, value: u64) {
	for byte := 0; byte < 8; byte += 1 {
		output[offset + byte] = u8(value >> u64(56 - byte * 8))
	}
}

@(export)
ascon_digest :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 2 { return -1 }
	variant, message_length_value := input[0], input[1]
	if (variant != 0 && variant != 1) || message_length_value < 0 ||
		message_length_value > MAX_MESSAGE_BYTES || length != c.size_t(message_length_value + 2) { return -1 }
	message_length := int(message_length_value)
	for index := 0; index < message_length; index += 1 {
		if input[index + 2] < 0 || input[index + 2] > 255 { return -1 }
	}

	state := [5]u64{}
	if variant == 0 {
		state = [5]u64{0xee9398aadb67f03d, 0x8bb21831c60f1002, 0xb48a92db98d5da62,
			0x43189921b8f8e3e8, 0x348fa5c9d525e140}
	} else {
		state = [5]u64{0x01470194fc6528a6, 0x738ec38ac0adffa7, 0x2ec8e3296c76384c,
			0xd6f6a54d7f52377d, 0xa13c42a223be8d87}
	}
	rounds := 12
	if variant == 1 { rounds = 8 }
	complete_length := message_length - message_length % 8
	for offset := 0; offset < complete_length; offset += 8 {
		word: u64 = 0
		for byte := 0; byte < 8; byte += 1 { word = (word << 8) | u64(input[offset + byte + 2]) }
		state[0] ~= word
		permute(&state[0], rounds)
	}
	tail_length := message_length - complete_length
	final_word := u64(0x80) << u64(56 - tail_length * 8)
	for byte := 0; byte < tail_length; byte += 1 {
		final_word |= u64(input[complete_length + byte + 2]) << u64(56 - byte * 8)
	}
	state[0] ~= final_word
	permute(&state[0], 12)

	if output == nil || capacity < 32 { return -2 }
	for block := 0; block < 4; block += 1 {
		write_u64_be(output, block * 8, state[0])
		if block != 3 { permute(&state[0], rounds) }
	}
	return 32
}
