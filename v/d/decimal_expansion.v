module decimal_expansion

fn write_i64_le(mut output &u8, offset int, value i64) {
	if value == -1 {
		for byte in 0 .. 8 { unsafe { output[offset + byte] = 0xff } }
		return
	}
	bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8((bits >> (8 * byte)) & 0xff) }
	}
}

@[export: 'decimal_expansion']
pub fn decimal_expansion(values &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { values == nil } || length != 3 { return -1 }
	unsafe {
		numerator := values[0]
		denominator := values[1]
		base := values[2]
		if numerator < 0 || denominator < 1 || denominator > 256 ||
			numerator > denominator || base < 2 || base > 10 { return -1 }

		mut digits := [255]u8{}
		mut first_seen := [256]i64{}
		for index in 0 .. 256 { first_seen[index] = -1 }
		mut digit_count := 0
		mut cycle_start := i64(-1)
		mut remainder := numerator
		for remainder != 0 && numerator != denominator {
			remainder_index := int(remainder)
			if first_seen[remainder_index] >= 0 {
				cycle_start = first_seen[remainder_index]
				break
			}
			first_seen[remainder_index] = i64(digit_count)
			scaled := remainder * base
			digits[digit_count] = u8(scaled / denominator)
			digit_count++
			remainder = scaled % denominator
		}

		required := 24 + digit_count
		if output == nil || capacity < usize(required) { return -2 }
		integer_part := if numerator == denominator { i64(1) } else { i64(0) }
		write_i64_le(mut output, 0, integer_part)
		write_i64_le(mut output, 8, i64(digit_count))
		write_i64_le(mut output, 16, cycle_start)
		for index in 0 .. digit_count { output[24 + index] = digits[index] }
		return i64(required)
	}
}
