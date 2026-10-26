module beebs_bit_compress

@[export: 'beebs_bit_compress']
pub fn beebs_bit_compress(values &i64, length usize) i64 {
	unsafe {
		if values == nil || length != 2 { return -1 }
		if values[0] < 0 || values[0] > 4_294_967_295 || values[1] < 0 || values[1] > 4_294_967_295 { return -1 }
		mut data := u32(values[0])
		mut mask := u32(values[1])
		mut packed := u32(0)
		mut output_bit := u32(1)
		for mask != 0 {
			if mask & 1 != 0 {
				if data & 1 != 0 { packed |= output_bit }
				output_bit <<= 1
			}
			data >>= 1
			mask >>= 1
		}
		return i64(packed)
	}
}
