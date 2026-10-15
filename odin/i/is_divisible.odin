package is_divisible

// Remainder check from the pinned JavaScript and TypeScript sources.
@(export)
is_divisible :: proc "c" (dividend, divisor: u64) -> i64 {
	if dividend > 1_000_000_000 || divisor == 0 || divisor > 1_000_000_000 do return -1
	if dividend % divisor == 0 do return 1
	return 0
}
