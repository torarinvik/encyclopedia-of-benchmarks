module factoring_exponentiation

const factor_log_32 = [32]u32{
	0x00000000, 0x00000000, 0xd3cfd984, 0x9ee62e18,
	0xe83d9070, 0xb59e81e0, 0xa17407c0, 0xce601f80,
	0xf4807f00, 0xe701fe00, 0xbe07fc00, 0xfc1ff800,
	0xf87ff000, 0xf1ffe000, 0xe7ffc000, 0xdfff8000,
	0xffff0000, 0xfffe0000, 0xfffc0000, 0xfff80000,
	0xfff00000, 0xffe00000, 0xffc00000, 0xff800000,
	0xff000000, 0xfe000000, 0xfc000000, 0xf8000000,
	0xf0000000, 0xe0000000, 0xc0000000, 0x80000000,
}

fn factoring_mask(d u32) u64 {
	if d == 32 { return u64(0xffffffff) }
	return (u64(1) << d) - 1
}

fn factoring_log(remainder_input u64, value_input u64, d u32, modulus u64, mask u64) u64 {
	mut remainder := remainder_input
	mut value := value_input
	for bit := u32(2); bit < d; bit++ {
		if (value & (u64(1) << bit)) != 0 {
			value = (value + (value << bit)) & mask
			remainder = (remainder + modulus - (u64(factor_log_32[int(bit)]) & mask)) & mask
		}
	}
	return remainder
}

fn factoring_exp(remainder_input u64, exponent_input u64, d u32, modulus u64, mask u64) u64 {
	mut remainder := remainder_input
	mut exponent := exponent_input
	for bit := u32(2); bit < d; bit++ {
		if (exponent & (u64(1) << bit)) != 0 {
			remainder = (remainder + (remainder << bit)) & mask
			exponent = (exponent + modulus - (u64(factor_log_32[int(bit)]) & mask)) & mask
		}
	}
	return remainder
}

@[export: 'factoring_exponentiation']
pub fn factoring_exponentiation(input &i64, length usize) i64 {
	if unsafe { input == nil } || length != 4 { return -1 }
	remainder_input := unsafe { input[0] }
	base_input := unsafe { input[1] }
	exponent_input := unsafe { input[2] }
	d_input := unsafe { input[3] }
	if d_input < 3 || d_input > 32 || remainder_input < 0 || base_input < 1 ||
		exponent_input < 0 || exponent_input > 4294967295 { return -1 }
	d := u32(d_input)
	mask := factoring_mask(d)
	modulus := mask + 1
	remainder := u64(remainder_input)
	base := u64(base_input)
	exponent := u64(exponent_input)
	if remainder >= modulus || base >= modulus || (base & 1) == 0 { return -1 }
	if (base & 2) != 0 {
		base = (modulus - base) & mask
		if (exponent & 1) != 0 { remainder = (modulus - remainder) & mask }
	}
	log_value := factoring_log(0, base, d, modulus, mask)
	scaled_log := (log_value * exponent) & mask
	return i64(factoring_exp(remainder, scaled_log, d, modulus, mask))
}
