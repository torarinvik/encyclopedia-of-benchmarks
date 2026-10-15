module armstrong_digit_cubes

// Match n against the signed sum of the cubes of its decimal digits.
@[export: 'armstrong_digit_cubes']
pub fn armstrong_digit_cubes(n i64) i64 {
	if n < -2_147_483_648 || n > 2_147_483_647 { return -1 }
	original := n
	mut magnitude := n
	if magnitude < 0 { magnitude = -magnitude }
	mut sum := i64(0)
	for magnitude > 0 {
		digit := magnitude % 10
		sum += digit * digit * digit
		magnitude /= 10
	}
	if original < 0 { sum = -sum }
	return if sum == original { i64(1) } else { i64(0) }
}
