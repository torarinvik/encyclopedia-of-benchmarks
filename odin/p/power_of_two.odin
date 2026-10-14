package power_of_two

// Return 1 when n is a positive power of two, otherwise 0.
@(export)
power_of_two :: proc "c" (n: i64) -> i64 {
	if n <= 0 do return 0
	if (n & (n - 1)) == 0 do return 1
	return 0
}
