module arithmetic_right_shift

const max_u53 = u64(9_007_199_254_740_991)
const invalid_result = i64(-1)

@[export: 'arithmetic_right_shift']
pub fn arithmetic_right_shift(n u64, shift u64) i64 {
	if n > max_u53 || shift > 53 { return invalid_result }
	count := u32(shift)
	low_mask := (u64(1) << u32(53 - shift)) - u64(1)
	shifted := n >> count
	mut fill_mask := u64(0)
	if n >> 52 != 0 { fill_mask = max_u53 ^ low_mask }
	return i64(fill_mask | shifted)
}
