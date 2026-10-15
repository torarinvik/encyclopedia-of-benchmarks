module highest_common_factor

fn highest_common_factor_impl(x u64, y u64) u64 {
	if x == 0 { return y }
	if y == 0 { return x }
	if x == y { return x }
	if y > x { return highest_common_factor_impl(y - x, x) }
	return highest_common_factor_impl(x - y, y)
}

@[export: 'highest_common_factor']
pub fn highest_common_factor(x u64, y u64) i64 {
	return i64(highest_common_factor_impl(x, y))
}
