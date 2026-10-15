package find_nth_bit

MAX_NUM :: u64(2_147_483_647)
INVALID_RESULT :: i64 = -1

@(export)
find_nth_bit :: proc "c" (num: u64, n: u64) -> i64 {
	if num > MAX_NUM || n < 1 || n > 31 do return INVALID_RESULT
	value := i32(num)
	shift := i32(n - 1)
	return i64((value & (i32(1) << shift)) >> shift)
}
