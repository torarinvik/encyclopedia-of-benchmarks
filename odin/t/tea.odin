package tea

import "core:c"

TEA_DELTA :: u32(0x9e3779b9)
TEA_DECRYPT_SUM :: u32(0xc6ef3720)

combine_words :: proc "contextless" (low, high: u32) -> u64 {
	return (u64(high) << 32) | u64(low)
}

tea_encrypt :: proc "contextless" (block, key0, key1: u64) -> u64 {
	b0, b1 := u32(block), u32(block >> 32)
	k0, k1 := u32(key0), u32(key0 >> 32)
	k2, k3 := u32(key1), u32(key1 >> 32)
	sum := u32(0)
	for round := 0; round < 32; round += 1 {
		sum += TEA_DELTA
		b0 += ((b1 << 4) + k0) ^ (b1 + sum) ^ ((b1 >> 5) + k1)
		b1 += ((b0 << 4) + k2) ^ (b0 + sum) ^ ((b0 >> 5) + k3)
	}
	return (u64(b1) << 32) | u64(b0)
}

tea_decrypt :: proc "contextless" (block, key0, key1: u64) -> u64 {
	b0, b1 := u32(block), u32(block >> 32)
	k0, k1 := u32(key0), u32(key0 >> 32)
	k2, k3 := u32(key1), u32(key1 >> 32)
	sum := TEA_DECRYPT_SUM
	for round := 0; round < 32; round += 1 {
		b1 -= ((b0 << 4) + k2) ^ (b0 + sum) ^ ((b0 >> 5) + k3)
		b0 -= ((b1 << 4) + k0) ^ (b1 + sum) ^ ((b1 >> 5) + k1)
		sum -= TEA_DELTA
	}
	return (u64(b1) << 32) | u64(b0)
}

store_u64_le :: proc "contextless" (output: [^]u8, offset: int, value: u64) {
	for byte := 0; byte < 8; byte += 1 {
		output[offset + byte] = u8((value >> u64(byte * 8)) & 255)
	}
}

@(export)
tea :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || length != 6 do return -1
	for index := 0; index < 6; index += 1 {
		if input[index] < -2147483648 || input[index] > 2147483647 do return -1
	}
	if output == nil || output_capacity < 16 do return -2
	block := combine_words(u32(i32(input[0])), u32(i32(input[1])))
	key0 := combine_words(u32(i32(input[2])), u32(i32(input[3])))
	key1 := combine_words(u32(i32(input[4])), u32(i32(input[5])))
	ciphertext := tea_encrypt(block, key0, key1)
	recovered := tea_decrypt(ciphertext, key0, key1)
	store_u64_le(output, 0, ciphertext)
	store_u64_le(output, 8, recovered)
	return 16
}
