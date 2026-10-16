module problem24

@[export: 'problem24']
pub fn problem24(ignored i64) i64 {
	if ignored != 0 { return -1 }
	mut rank := i64(999999)
	mut factorial := i64(362880)
	mut used := i64(0)
	mut result := i64(0)
	mut slots := i64(10)
	for slots > 0 {
		mut choice := rank / factorial
		rank %= factorial
		mut selected := i64(-1)
		mut digit := i64(0)
		for digit < 10 {
			bit := i64(1) << u32(digit)
			if used & bit == 0 {
				if choice == 0 {
					selected = digit
					used |= bit
					break
				}
				choice--
			}
			digit++
		}
		result = result * 10 + selected
		if slots > 1 { factorial /= slots - 1 }
		slots--
	}
	return result
}
