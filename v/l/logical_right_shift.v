module logical_right_shift

const max_u53 = u64(9_007_199_254_740_991)
const invalid_result = i64(-1)

@[export: 'logical_right_shift']
pub fn logical_right_shift(n u64, shift u64) i64 {
	if n > max_u53 || shift > 53 { return invalid_result }
	return i64(n >> u32(shift))
}
