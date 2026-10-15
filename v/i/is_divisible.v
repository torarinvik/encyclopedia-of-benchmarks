module is_divisible

// Remainder check from the pinned JavaScript and TypeScript sources.
@[export: 'is_divisible']
pub fn is_divisible(dividend u64, divisor u64) i64 {
	if dividend > 1000000000 || divisor == 0 || divisor > 1000000000 {
		return -1
	}
	if dividend % divisor == 0 {
		return 1
	}
	return 0
}
