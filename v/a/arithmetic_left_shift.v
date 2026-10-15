module arithmetic_left_shift

const max_u53 = u64(9_007_199_254_740_991)
const invalid_result = i64(-1)

@[export: 'arithmetic_left_shift']
pub fn arithmetic_left_shift(n u64, shift u64) i64 {
	if n > max_u53 || shift > 53 { return invalid_result }
	return i64((n << u32(shift)) & max_u53)
}
