package is_even

// Return 1 for even and 0 for odd signed 64-bit integers.
@(export)
is_even :: proc "c" (value: i64) -> i64 {
	if value % 2 == 0 do return 1
	return 0
}
