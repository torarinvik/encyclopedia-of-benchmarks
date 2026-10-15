package armstrong_digit_cubes

// Match n against the signed sum of the cubes of its decimal digits.
@(export)
armstrong_digit_cubes :: proc "c" (n: i64) -> i64 {
	if n < -2_147_483_648 || n > 2_147_483_647 do return -1
	original := n
	magnitude := n
	if magnitude < 0 do magnitude = -magnitude
	sum := i64(0)
	for magnitude > 0 {
		digit := magnitude % 10
		sum += digit * digit * digit
		magnitude /= 10
	}
	if original < 0 do sum = -sum
	if sum == original do return 1
	return 0
}
