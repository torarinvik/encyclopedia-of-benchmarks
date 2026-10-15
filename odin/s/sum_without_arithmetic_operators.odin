package sum_without_arithmetic_operators

add_recursive :: proc "contextless" (a, b: u32) -> u32 {
	if b == 0 do return a
	return add_recursive(a ~ b, (a & b) << 1)
}

@(export)
sum_without_arithmetic_operators :: proc "contextless" (a, b: i64) -> i64 {
	if a < -2_147_483_648 || a > 2_147_483_647 || b < -2_147_483_648 || b > 2_147_483_647 do return -2_147_483_649
	bits := add_recursive(u32(i32(a)), u32(i32(b)))
	if bits <= 2_147_483_647 do return i64(bits)
	return i64(bits) - 4_294_967_296
}
