package is_odd

// Return 1 for odd and 0 for even signed 64-bit integers.
@(export)
is_odd :: proc "c" (value: i64) -> i64 {
	if value % 2 != 0 do return 1
	return 0
}
