package sha3

import "core:c"

MAX_MESSAGE_BYTES :: 4096
MAX_PARSEABLE_INPUT_LENGTH :: 4099
MAX_OUTPUT_BYTES :: 64
ROUND_CONSTANTS :: [24]u64{
	0x0000000000000001,0x0000000000008082,0x800000000000808a,0x8000000080008000,
	0x000000000000808b,0x0000000080000001,0x8000000080008081,0x8000000000008009,
	0x000000000000008a,0x0000000000000088,0x0000000080008009,0x000000008000000a,
	0x000000008000808b,0x800000000000008b,0x8000000080008089,0x8000000000008003,
	0x8000000000008002,0x8000000000000080,0x000000000000800a,0x800000008000000a,
	0x8000000080008081,0x8000000000008080,0x0000000080000001,0x8000000080008008,
}
ROTATION_OFFSETS :: [25]u32{0,1,62,28,27,36,44,6,55,20,3,10,43,25,39,41,45,15,21,8,18,2,61,56,14}

rotate_left :: proc "contextless" (value: u64, amount: u32) -> u64 {
	if amount == 0 do return value
	return (value << amount) | (value >> (64 - amount))
}

keccak_f :: proc "contextless" (state: [^]u64) {
	for round := 0; round < 24; round += 1 {
		column: [5]u64 = {}
		delta: [5]u64 = {}
		moved: [25]u64 = {}
		for x := 0; x < 5; x += 1 {
			column[x] = state[x] ^ state[x + 5] ^ state[x + 10] ^ state[x + 15] ^ state[x + 20]
		}
		for x := 0; x < 5; x += 1 { delta[x] = column[(x + 4) % 5] ^ rotate_left(column[(x + 1) % 5], 1) }
		for y := 0; y < 5; y += 1 { for x := 0; x < 5; x += 1 { state[x + 5 * y] = state[x + 5 * y] ^ delta[x] } }
		for y := 0; y < 5; y += 1 {
			for x := 0; x < 5; x += 1 {
				source := x + 5 * y
				target := y + 5 * ((2 * x + 3 * y) % 5)
				moved[target] = rotate_left(state[source], ROTATION_OFFSETS[source])
			}
		}
		for y := 0; y < 5; y += 1 {
			for x := 0; x < 5; x += 1 {
				state[x + 5 * y] = moved[x + 5 * y] ^ ((~moved[(x + 1) % 5 + 5 * y]) & moved[(x + 2) % 5 + 5 * y])
			}
		}
		state[0] = state[0] ^ ROUND_CONSTANTS[round]
	}
}

absorb_byte :: proc "contextless" (state: [^]u64, offset: int, value: u8) {
	state[offset / 8] = state[offset / 8] ^ (u64(value) << u32((offset % 8) * 8))
}

sha3_digest :: proc "contextless" (variant: int, input: [^]i64, message_length: int) -> [64]u8 {
	digest_lengths := [4]int{28,32,48,64}
	rates := [4]int{144,136,104,72}
	rate := rates[variant]
	state: [25]u64 = {}
	offset := 0
	for message_length - offset >= rate {
		for index := 0; index < rate; index += 1 { absorb_byte(&state[0], index, u8(input[2 + offset + index])) }
		keccak_f(&state[0])
		offset += rate
	}
	block: [144]u8 = {}
	remaining := message_length - offset
	for index := 0; index < remaining; index += 1 { block[index] = u8(input[2 + offset + index]) }
	block[remaining] = block[remaining] ^ 0x06
	block[rate - 1] = block[rate - 1] ^ 0x80
	for index := 0; index < rate; index += 1 { absorb_byte(&state[0], index, block[index]) }
	keccak_f(&state[0])
	digest: [64]u8 = {}
	for index := 0; index < digest_lengths[variant]; index += 1 { digest[index] = u8((state[index / 8] >> u32((index % 8) * 8)) & 255) }
	return digest
}

@(export)
sha3 :: proc "c" (input: [^]i64, input_length: c.size_t,
	output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || input_length < 2 || input_length > c.size_t(MAX_PARSEABLE_INPUT_LENGTH) do return -1
	if input[0] < 0 || input[0] > 3 || input[1] < 0 || input[1] > MAX_MESSAGE_BYTES do return -1
	variant, message_length := int(input[0]), int(input[1])
	if int(input_length) != 2 + message_length do return -1
	for index := 0; index < message_length; index += 1 { if input[2 + index] < 0 || input[2 + index] > 255 do return -1 }
	digest_lengths := [4]int{28,32,48,64}
	digest_length := digest_lengths[variant]
	if digest_length > MAX_OUTPUT_BYTES do return -1
	if output == nil || output_capacity < c.size_t(digest_length) do return -2
	digest := sha3_digest(variant, input, message_length)
	for index := 0; index < digest_length; index += 1 { output[index] = digest[index] }
	return i64(digest_length)
}
