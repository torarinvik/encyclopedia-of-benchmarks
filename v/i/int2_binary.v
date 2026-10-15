module int2_binary

// Encode the C# uint overload as exactly 32 ASCII binary digits.
@[export: 'int2_binary']
pub fn int2_binary(value i64, output &u8, output_capacity usize) i64 {
	if value < 0 || value > 4_294_967_295 { return -1 }
	if output_capacity < 32 { return -2 }

	mut remaining := u32(value)
	mut most_significant_bit := u32(0x80000000)
	unsafe {
		for i := usize(0); i < 32; i++ {
			if remaining >= most_significant_bit {
				output[i] = u8(49)
				remaining -= most_significant_bit
			} else {
				output[i] = u8(48)
			}
			most_significant_bit /= 2
		}
	}
	return 32
}
