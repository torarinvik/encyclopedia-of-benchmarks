package chacha

import "core:c"

CHACHA_WORDS :: 16
CHACHA_BYTES :: 64
WORD_MASK :: u64(0xffff_ffff)

rotate_left :: proc "contextless" (value: u64, count: u64) -> u64 {
	return ((value << count) | (value >> (32 - count))) & WORD_MASK
}

quarter_round :: proc "contextless" (state: [^]u64, a, b, c_index, d: int) {
	state[a] = (state[a] + state[b]) & WORD_MASK
	state[d] = rotate_left(state[d] ~ state[a], 16)
	state[c_index] = (state[c_index] + state[d]) & WORD_MASK
	state[b] = rotate_left(state[b] ~ state[c_index], 12)
	state[a] = (state[a] + state[b]) & WORD_MASK
	state[d] = rotate_left(state[d] ~ state[a], 8)
	state[c_index] = (state[c_index] + state[d]) & WORD_MASK
	state[b] = rotate_left(state[b] ~ state[c_index], 7)
}

@(export)
chacha :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || length != CHACHA_WORDS do return -1
	initial: [CHACHA_WORDS]u64
	for index := 0; index < CHACHA_WORDS; index += 1 {
		if input[index] < 0 || input[index] > 4294967295 do return -1
		initial[index] = u64(input[index])
	}
	if output == nil || output_capacity < CHACHA_BYTES do return -2

	state := initial
	for round := 0; round < 10; round += 1 {
		quarter_round(&state[0], 0, 4, 8, 12)
		quarter_round(&state[0], 1, 5, 9, 13)
		quarter_round(&state[0], 2, 6, 10, 14)
		quarter_round(&state[0], 3, 7, 11, 15)
		quarter_round(&state[0], 0, 5, 10, 15)
		quarter_round(&state[0], 1, 6, 11, 12)
		quarter_round(&state[0], 2, 7, 8, 13)
		quarter_round(&state[0], 3, 4, 9, 14)
	}
	for index := 0; index < CHACHA_WORDS; index += 1 {
		word := (state[index] + initial[index]) & WORD_MASK
		output[4 * index] = u8(word & 0xff)
		output[4 * index + 1] = u8((word >> 8) & 0xff)
		output[4 * index + 2] = u8((word >> 16) & 0xff)
		output[4 * index + 3] = u8((word >> 24) & 0xff)
	}
	return CHACHA_BYTES
}
