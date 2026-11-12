package nim_product_64

import "core:c"

nim_product :: proc(a, b: u64, width: int) -> u64 {
	if width == 1 do return a & b
	half := width / 2
	mask := (u64(1) << half) - 1
	a_low, a_high := a & mask, a >> half
	b_low, b_high := b & mask, b >> half
	low_product := nim_product(a_low, b_low, half)
	high_product := nim_product(a_high, b_high, half)
	cross := nim_product(a_low ^ a_high, b_low ^ b_high, half) ^ low_product ^ high_product
	constant := u64(1) << (half - 1)
	low := low_product ^ nim_product(high_product, constant, half)
	high := cross ^ high_product
	return low ^ (high << half)
}

@(export)
nim_product_64 :: proc "c" (input: [^]i64, length: c.size_t,
							 output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || length != 4 do return -1
	for index := 0; index < 4; index += 1 {
		if input[index] < 0 || input[index] > 4_294_967_295 do return -1
	}
	if output == nil || output_capacity < 8 do return -2

	a := u64(input[0]) | (u64(input[1]) << 32)
	b := u64(input[2]) | (u64(input[3]) << 32)
	result := nim_product(a, b, 64)
	for index := 0; index < 8; index += 1 {
		output[index] = u8(result >> (8 * index))
	}
	return 8
}
