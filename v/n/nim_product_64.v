module nim_product_64

fn nim_product(a u64, b u64, width int) u64 {
	if width == 1 { return a & b }
	half := width / 2
	mask := (u64(1) << half) - u64(1)
	a_low := a & mask
	a_high := a >> half
	b_low := b & mask
	b_high := b >> half
	low_product := nim_product(a_low, b_low, half)
	high_product := nim_product(a_high, b_high, half)
	cross := nim_product(a_low ^ a_high, b_low ^ b_high, half) ^ low_product ^ high_product
	constant := u64(1) << (half - 1)
	low := low_product ^ nim_product(high_product, constant, half)
	high := cross ^ high_product
	return low ^ (high << half)
}

@[export: 'nim_product_64']
pub fn nim_product_64(input &i64, length usize, mut output &u8, output_capacity usize) i64 {
	if unsafe { input == nil } || length != 4 { return -1 }
	unsafe {
		for index in 0 .. 4 {
			if input[index] < 0 || input[index] > 4_294_967_295 { return -1 }
		}
		if output == nil || output_capacity < 8 { return -2 }
		a := u64(input[0]) | (u64(input[1]) << 32)
		b := u64(input[2]) | (u64(input[3]) << 32)
		result := nim_product(a, b, 64)
		for index in 0 .. 8 {
			output[index] = u8(result >> (8 * index))
		}
		return 8
	}
}
