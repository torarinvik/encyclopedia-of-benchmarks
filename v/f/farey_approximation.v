module farey_approximation

fn store_i64_le(mut output &u8, offset int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8((bits >> (byte * 8)) & 255) }
	}
}

@[export: 'farey_approximation']
pub fn farey_approximation(values &i64, length usize, mut output &u8, output_capacity usize) i64 {
	if length != 2 || unsafe { values == nil } { return -1 }
	unsafe {
		decimal_millionths := values[0]
		repeat := values[1]
		if decimal_millionths < 1 || decimal_millionths > 999999 || repeat < 1 || repeat > 20 { return -1 }
		if unsafe { output == nil } || output_capacity < 16 { return -2 }

		decimal := f64(decimal_millionths) / 1000000.0
		mut a := i64(0)
		mut b := i64(1)
		mut c := i64(1)
		mut d := i64(1)
		mut numerator := i64(0)
		mut denominator := i64(0)
		for _ in 0 .. int(repeat) {
			numerator = a + c
			denominator = b + d
			if decimal > f64(numerator) / f64(denominator) {
				a = numerator
				b = denominator
			} else {
				c = numerator
				d = denominator
			}
		}
		store_i64_le(output, 0, numerator)
		store_i64_le(output, 8, denominator)
		return 16
	}
}
