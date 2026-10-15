package logical_right_shift

MAX_U53 :: u64(9_007_199_254_740_991)
INVALID_RESULT :: i64 = -1

@(export)
logical_right_shift :: proc "c" (n: u64, shift: u64) -> i64 {
	if n > MAX_U53 || shift > 53 do return INVALID_RESULT
	return i64(n >> u32(shift))
}
