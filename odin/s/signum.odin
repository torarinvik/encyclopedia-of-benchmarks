package signum

// Sign of a signed 64-bit integer.
@(export)
signum :: proc "c" (value: i64) -> i64 {
	if value > 0 do return 1
	if value < 0 do return -1
	return 0
}
