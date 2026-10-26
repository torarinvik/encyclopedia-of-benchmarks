module prolangs_c_numeric_token

import math

fn put_i32(out &u8, at int, value i32) {
	bits := u32(value)
	for b := 0; b < 4; b++ { unsafe { out[at + b] = u8((bits >> (b * 8)) & 255) } }
}

@[export: 'prolangs_c_numeric_token']
pub fn prolangs_c_numeric_token(input &i64, length usize, output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 1 || length > 24 { return -1 }
		mut text := [24]u8{}
		for j := 0; j < int(length); j++ { if input[j] < 32 || input[j] > 127 { return -1 }; text[j] = u8(input[j]) }
	mut i := 0
	mut integer := u32(0)
	mut had_integer := false
	if text[i] >= 48 && text[i] <= 57 {
		had_integer = true
		for i < int(length) && text[i] >= 48 && text[i] <= 57 {
			d := u32(text[i] - 48); i++
			if integer > (u32(2147483647) - d) / 10 { return -1 }
			integer = integer * 10 + d
		}
		if i == int(length) {
			if output == nil || capacity < 12 { return -2 }
			put_i32(output, 0, 256); put_i32(output, 4, i32(integer)); put_i32(output, 8, 0); return 12
		}
	}
	mut frac_digits := u32(0); mut frac_count := 0; mut leading_zeros := 0; mut has_dot := false
	if i < int(length) && text[i] == 46 {
		has_dot = true; i++
		for i < int(length) && text[i] == 48 { leading_zeros++; i++ }
		if leading_zeros > 6 { return -1 }
		for i < int(length) && text[i] >= 48 && text[i] <= 57 {
			if frac_count == 6 { return -1 }
			frac_digits = frac_digits * 10 + u32(text[i] - 48); frac_count++; i++
		}
		if leading_zeros + frac_count > 6 { return -1 }
	}
	mut value := f32(0)
	if frac_count != 0 {
		value = f32(frac_digits)
		for value >= 1 { value /= 10 }
		for leading_zeros > 0 { value /= 10; leading_zeros-- }
	}
	value += f32(integer)
	mut has_exp := false
	if i < int(length) && (text[i] == 101 || text[i] == 69) {
		has_exp = true; i++; mut sign := 1
		if i < int(length) && (text[i] == 43 || text[i] == 45) { if text[i] == 45 { sign = -1 }; i++ }
		if i == int(length) || text[i] < 48 || text[i] > 57 { return -1 }
		mut exponent := 0
		for i < int(length) && text[i] >= 48 && text[i] <= 57 { exponent = exponent * 10 + int(text[i] - 48); i++; if exponent > 6 { return -1 } }
		exponent *= sign
		for exponent > 0 { value *= 10; exponent-- }
		for exponent < 0 { value /= 10; exponent++ }
	}
	if i != int(length) || (!has_dot && !has_exp) || (!had_integer && !has_dot) { return -1 }
	if output == nil || capacity < 12 { return -2 }
	put_i32(output, 0, 2001); put_i32(output, 4, i32(integer)); put_i32(output, 8, i32(math.f32_bits(value)))
	return 12
	}
}
