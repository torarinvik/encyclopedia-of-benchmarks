package abs

// Return the signed 64-bit magnitude, or -1 when it cannot be represented.
@(export)
abs_i64 :: proc "c" (input: i64) -> i64 {
	if input == -9223372036854775807 - 1 do return -1
	if input < 0 do return -input
	return input
}
