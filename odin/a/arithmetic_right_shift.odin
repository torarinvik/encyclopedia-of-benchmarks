package arithmetic_right_shift

MAX_U53 :: u64(9_007_199_254_740_991)
INVALID_RESULT :: i64 = -1

@(export)
arithmetic_right_shift :: proc "c" (n: u64, shift: u64) -> i64 {
	if n > MAX_U53 || shift > 53 do return INVALID_RESULT
	count := u32(shift)
	low_mask := (u64(1) << u32(53 - shift)) - u64(1)
	shifted := n >> count
	fill_mask := u64(0)
	if n >> 52 != 0 do fill_mask = MAX_U53 ^ low_mask
	return i64(fill_mask | shifted)
}
