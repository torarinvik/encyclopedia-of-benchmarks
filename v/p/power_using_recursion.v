module power_using_recursion

// Linear recursive integer power, with a bounded exact contract.
fn decode_signed(value u64) i64 {
	if value <= u64(i64(0x7fffffffffffffff)) { return i64(value) }
	return -1 - i64(~value)
}

fn power_recursive(base i64, exponent u64) i64 {
	if exponent == 0 { return 1 }
	return base * power_recursive(base, exponent - 1)
}

@[export: 'power_using_recursion']
pub fn power_using_recursion(base_encoded u64, exponent u64) i64 {
	base := decode_signed(base_encoded)
	if base < -10 || base > 10 || exponent > 15 { return i64(-9223372036854775808) }
	return power_recursive(base, exponent)
}
