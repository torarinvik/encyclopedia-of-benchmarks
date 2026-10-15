package highest_common_factor

highest_common_factor_impl :: proc "contextless" (x, y: u64) -> u64 {
	if x == 0 do return y
	if y == 0 do return x
	if x == y do return x
	if y > x do return highest_common_factor_impl(y - x, x)
	return highest_common_factor_impl(x - y, y)
}

@(export)
highest_common_factor :: proc "c" (x, y: u64) -> i64 {
	return i64(highest_common_factor_impl(x, y))
}
