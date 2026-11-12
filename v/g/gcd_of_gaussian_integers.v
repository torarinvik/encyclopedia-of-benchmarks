module gcd_of_gaussian_integers

const max_t = 8
const max_component = i64(1000000)
const max_output_bytes = 64

fn gaussian_nearest_quotient(numerator i64, denominator i64) i64 {
	mut sign := i64(1)
	mut magnitude := numerator
	if numerator < 0 {
		sign = -1
		magnitude = -numerator
	}
	mut quotient := magnitude / denominator
	remainder := magnitude % denominator
	if 2 * remainder >= denominator { quotient++ }
	return sign * quotient
}

fn gaussian_write_u32(output &u8, offset int, value u32) {
	unsafe {
		output[offset] = u8(value)
		output[offset + 1] = u8(value >> 8)
		output[offset + 2] = u8(value >> 16)
		output[offset + 3] = u8(value >> 24)
	}
}

@[export: 'gcd_of_gaussian_integers']
pub fn gcd_of_gaussian_integers(input &i64, length usize, output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 5 || length > 33 { return -1 }
		t64 := input[0]
		if t64 < 1 || t64 > i64(max_t) { return -1 }
		t := int(t64)
		if length != usize(1 + 4 * t) { return -1 }

		mut values := [32]i64{}
		for index in 0 .. 4 * t {
			value := input[index + 1]
			if value < -max_component || value > max_component { return -1 }
			values[index] = value
		}
		required := 8 * t
		if output == nil || capacity < usize(required) || required > max_output_bytes { return -2 }

		for test in 0 .. t {
			mut ar := values[4 * test]
			mut ai := values[4 * test + 1]
			mut br := values[4 * test + 2]
			mut bi := values[4 * test + 3]
			for br != 0 || bi != 0 {
				denominator := br * br + bi * bi
				qr := gaussian_nearest_quotient(ar * br + ai * bi, denominator)
				qi := gaussian_nearest_quotient(ai * br - ar * bi, denominator)
				rr := ar - (qr * br - qi * bi)
				ri := ai - (qr * bi + qi * br)
				ar, ai, br, bi = br, bi, rr, ri
			}
			if ar != 0 || ai != 0 {
				for rotation in 0 .. 4 {
					if ar > 0 && ai >= 0 { break }
					old_real := ar
					ar, ai = -ai, old_real
				}
			}
			gaussian_write_u32(output, 8 * test, u32(ar))
			gaussian_write_u32(output, 8 * test + 4, u32(ai))
		}
		return i64(required)
	}
}
