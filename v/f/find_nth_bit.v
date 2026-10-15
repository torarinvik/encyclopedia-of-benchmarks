module find_nth_bit

const max_num = u64(2_147_483_647)
const invalid_result = i64(-1)

@[export: 'find_nth_bit']
pub fn find_nth_bit(num u64, n u64) i64 {
	if num > max_num || n < 1 || n > 31 { return invalid_result }
	value := i32(num)
	shift := i32(n - 1)
	return i64((value & (i32(1) << shift)) >> shift)
}
