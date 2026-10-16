package problem24

@(export)
problem24 :: proc "c" (ignored: i64) -> i64 {
	if ignored != 0 do return -1
	rank := i64(999999)
	factorial := i64(362880)
	used := i64(0)
	result := i64(0)
	for slots := i64(10); slots > 0; slots -= 1 {
		choice := rank / factorial
		rank %= factorial
		selected := i64(-1)
		for digit := i64(0); digit < 10; digit += 1 {
			bit := i64(1) << u32(digit)
			if (used & bit) != 0 do continue
			if choice == 0 {
				selected = digit
				used |= bit
				break
			}
			choice -= 1
		}
		result = result * 10 + selected
		if slots > 1 do factorial /= slots - 1
	}
	return result
}
