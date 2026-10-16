fn round_div_even(numerator i64, denominator i64) i64 {
	negative := numerator < 0
	mut magnitude := u64(numerator)
	if negative { magnitude = u64(-numerator) }
	divisor := u64(denominator)
	mut quotient := magnitude / divisor
	remainder := magnitude % divisor
	if remainder * 2 > divisor || (remainder * 2 == divisor && quotient & 1 != 0) {
		quotient++
	}
	if negative { return -i64(quotient) }
	return i64(quotient)
}

fn put_i64_le(mut output &u8, offset int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8((bits >> (byte * 8)) & 255) }
	}
}

@[export: 'barnsley_fern']
pub fn barnsley_fern(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if isnil(input) || length < 1 { return -1 }
	iteration_value := unsafe { input[0] }
	if iteration_value < 1 || iteration_value > 4096 || length != usize(iteration_value) { return -1 }
	iterations := int(iteration_value)
	for step in 1 .. iterations {
		sample := unsafe { input[step] }
		if sample < 0 || sample >= 10_000 { return -1 }
	}
	output_length := iterations * 16
	if isnil(output) || capacity < usize(output_length) { return -2 }

	mut x := i64(0)
	mut y := i64(0)
	put_i64_le(mut output, 0, 0)
	put_i64_le(mut output, 8, 0)
	for step in 1 .. iterations {
		sample := unsafe { input[step] }
		mut a := i64(0)
		mut b := i64(0)
		mut c := i64(0)
		mut d := i64(0)
		mut f := i64(0)
		if sample < 100 {
			d = 16
		} else if sample < 8_600 {
			a = 85; b = 4; c = -4; d = 85; f = 160
		} else if sample < 9_300 {
			a = 20; b = -26; c = 23; d = 22; f = 160
		} else {
			a = -15; b = 28; c = 26; d = 24; f = 44
		}
		next_x := round_div_even(a * x + b * y, 100)
		next_y := round_div_even(c * x + d * y, 100) + f * i64(10_000_000_000)
		x = next_x
		y = next_y
		put_i64_le(mut output, step * 16, round_div_even(x, 1_000_000))
		put_i64_le(mut output, step * 16 + 8, round_div_even(y, 1_000_000))
	}
	return i64(output_length)
}
