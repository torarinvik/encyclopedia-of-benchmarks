package salsa

import "core:c"

SALSA_WORD_COUNT :: 16
SALSA_OUTPUT_BYTES :: 64

add32 :: proc "contextless" (left, right: u32) -> u32 {
	return u32(u64(left) + u64(right))
}

rotate_left :: proc "contextless" (value: u32, amount: u32) -> u32 {
	return (value << amount) | (value >> (32 - amount))
}

quarter_round :: proc "contextless" (state: [^]u32,
		first, second, third, fourth: int) {
	state[second] ^= rotate_left(add32(state[first], state[fourth]), 7)
	state[third] ^= rotate_left(add32(state[second], state[first]), 9)
	state[fourth] ^= rotate_left(add32(state[third], state[second]), 13)
	state[first] ^= rotate_left(add32(state[fourth], state[third]), 18)
}

store_u32_le :: proc "contextless" (output: [^]u8, offset: int, value: u32) {
	for byte := 0; byte < 4; byte += 1 {
		output[offset + byte] = u8((value >> u32(byte * 8)) & 255)
	}
}

@(export)
salsa :: proc "c" (input: [^]i32, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || length != SALSA_WORD_COUNT do return -1
	original: [SALSA_WORD_COUNT]u32
	for index := 0; index < SALSA_WORD_COUNT; index += 1 {
		original[index] = u32(input[index])
	}
	if output == nil || output_capacity < SALSA_OUTPUT_BYTES do return -2

	state: [SALSA_WORD_COUNT]u32
	for index := 0; index < SALSA_WORD_COUNT; index += 1 do state[index] = original[index]
	for round := 0; round < 10; round += 1 {
		quarter_round(&state[0], 0, 4, 8, 12)
		quarter_round(&state[0], 5, 9, 13, 1)
		quarter_round(&state[0], 10, 14, 2, 6)
		quarter_round(&state[0], 15, 3, 7, 11)
		quarter_round(&state[0], 0, 1, 2, 3)
		quarter_round(&state[0], 5, 6, 7, 4)
		quarter_round(&state[0], 10, 11, 8, 9)
		quarter_round(&state[0], 15, 12, 13, 14)
	}
	for index := 0; index < SALSA_WORD_COUNT; index += 1 {
		state[index] = add32(state[index], original[index])
		store_u32_le(output, index * 4, state[index])
	}
	return SALSA_OUTPUT_BYTES
}
