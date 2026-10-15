module sum_without_arithmetic_operators

fn add_recursive(a u32, b u32) u32 {
	if b == 0 { return a }
	return add_recursive(a ^ b, (a & b) << 1)
}

@[export: 'sum_without_arithmetic_operators']
pub fn sum_without_arithmetic_operators(a i64, b i64) i64 {
	if a < -2147483648 || a > 2147483647 || b < -2147483648 || b > 2147483647 { return -2147483649 }
	bits := add_recursive(u32(i32(a)), u32(i32(b)))
	if bits <= 2147483647 { return i64(bits) }
	return i64(bits) - 4294967296
}
