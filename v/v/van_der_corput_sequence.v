module van_der_corput_sequence

@[export: 'van_der_corput_sequence']
pub fn van_der_corput_sequence(input &i64, length usize, mut output &u8, output_capacity usize) i64 {
	unsafe {
		if input == nil || length != 3 { return -1 }
		base := input[0]
		first_index := input[1]
		count := input[2]
		if base < 2 || base > 16 || first_index < 1 || first_index > 4096
			|| count < 0 || count > 128
			|| (count > 0 && first_index + count - 1 > 4096) { return -1 }

		output_bytes := int(count) * 16
		if output == nil || output_capacity < usize(output_bytes) { return -2 }
		for offset in 0 .. int(count) {
			mut index := first_index + i64(offset)
			mut numerator := u64(0)
			mut denominator := u64(1)
			for index > 0 {
				numerator = numerator * u64(base) + u64(index % base)
				denominator *= u64(base)
				index /= base
			}
			position := offset * 16
			for byte in 0 .. 8 {
				output[position + byte] = u8((numerator >> (byte * 8)) & 255)
				output[position + 8 + byte] = u8((denominator >> (byte * 8)) & 255)
			}
		}
		return i64(output_bytes)
	}
}
