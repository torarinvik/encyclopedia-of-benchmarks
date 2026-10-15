package power_using_recursion

// Linear recursive integer power, with a bounded exact contract.
decode_signed :: proc "contextless" (value: u64) -> i64 {
	if value <= u64(max(i64)) do return i64(value)
	return -1 - i64(~value)
}

power_recursive :: proc "contextless" (base: i64, exponent: u64) -> i64 {
	if exponent == 0 do return 1
	return base * power_recursive(base, exponent - 1)
}

@(export)
power_using_recursion :: proc "c" (base_encoded, exponent: u64) -> i64 {
	base := decode_signed(base_encoded)
	if base < -10 || base > 10 || exponent > 15 do return -9223372036854775807 - 1
	return power_recursive(base, exponent)
}
