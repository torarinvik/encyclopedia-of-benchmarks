module binary_pow

fn mul32(x i64, y i64) i64 {
	x_low := x % 65536
	x_high := x / 65536
	y_low := y % 65536
	y_high := y / 65536
	cross := (x_low * y_high + x_high * y_low) % 65536
	return (x_low * y_low + cross * 65536) % 4294967296
}

@[export: 'binary_pow']
pub fn binary_pow(first i64, second i64) i64 {
	if first < -2147483648 || first > 2147483647 || second < -2147483648 || second > 2147483647 { return -2147483649 }
	if second <= 0 { return 1 }
	mut base := first
	if base < 0 { base += 4294967296 }
	mut exponent := second
	mut result := i64(1)
	for exponent > 0 {
		if exponent % 2 == 1 { result = mul32(result, base) }
		base = mul32(base, base)
		exponent /= 2
	}
	if result >= 2147483648 { return result - 4294967296 }
	return result
}
