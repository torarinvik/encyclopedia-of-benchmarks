package sdes

import "core:c"

P8: [8]u8 = {6,3,7,4,8,5,10,9}
P10: [10]u8 = {3,5,2,7,4,10,1,9,8,6}
P4: [4]u8 = {2,4,3,1}
IP: [8]u8 = {2,6,3,1,4,8,5,7}
IP_INV: [8]u8 = {4,1,3,5,7,2,8,6}
EXPANSION: [8]u8 = {4,1,2,3,2,3,4,1}
SBOXES: [32]u8 = {1,0,3,2,3,2,1,0,0,2,1,3,3,1,3,2,0,1,2,3,2,0,1,3,3,0,1,0,2,1,0,3}

table_value :: proc "contextless" (table: int, index: int) -> u32 {
	switch table {
	case 0: return u32(P8[index])
	case 1: return u32(P10[index])
	case 2: return u32(IP[index])
	case 3: return u32(IP_INV[index])
	case 4: return u32(EXPANSION[index])
	case: return u32(P4[index])
	}
}

permute :: proc "contextless" (value: u32, input_bits: u32, table: int, count: int) -> u32 {
	result: u32 = 0
	for index := 0; index < count; index += 1 {
		position := table_value(table, index)
		result = (result << 1) | ((value >> (input_bits - position)) & 1)
	}
	return result
}

rotate5 :: proc "contextless" (value: u32, amount: u32) -> u32 {
	return ((value << amount) | (value >> (5 - amount))) & 31
}

subkey :: proc "contextless" (key: u32, round: u32) -> u32 {
	selected := permute(key, 10, 1, 10)
	left, right := selected >> 5, selected & 31
	left = rotate5(left, 1)
	right = rotate5(right, 1)
	if round != 0 {
		left = rotate5(left, 2)
		right = rotate5(right, 2)
	}
	return permute((left << 5) | right, 10, 0, 8)
}

sbox_value :: proc "contextless" (box: int, nibble: u32) -> u32 {
	row := int(((nibble & 8) >> 2) | (nibble & 1))
	column := int((nibble >> 1) & 3)
	return u32(SBOXES[box*16+row*4+column])
}

fk :: proc "contextless" (state: u32, key: u32) -> u32 {
	left, right := state >> 4, state & 15
	mixed := permute(right, 4, 4, 8) ^ key
	substituted := (sbox_value(0, mixed >> 4) << 2) | sbox_value(1, mixed & 15)
	return ((left ^ permute(substituted, 4, 5, 4)) << 4) | right
}

crypt :: proc "contextless" (message: u32, key: u32, decrypt: bool) -> u32 {
	first, second := subkey(key, 0), subkey(key, 1)
	state := permute(message, 8, 2, 8)
	if decrypt { state = fk(state, second) } else { state = fk(state, first) }
	state = ((state & 15) << 4) | (state >> 4)
	if decrypt { state = fk(state, first) } else { state = fk(state, second) }
	return permute(state, 8, 3, 8)
}

@(export)
sdes :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || length != 2 do return -1
	if input[0] < 0 || input[0] > 1023 || input[1] < 0 || input[1] > 255 do return -1
	if output == nil || output_capacity < 2 do return -2
	key := u32(input[0])
	ciphertext := crypt(u32(input[1]), key, false)
	recovered := crypt(ciphertext, key, true)
	output[0] = u8(ciphertext)
	output[1] = u8(recovered)
	return 2
}
