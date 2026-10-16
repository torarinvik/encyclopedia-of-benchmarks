module trial_division_factorizer

@[export: 'trial_division_factorizer']
pub fn trial_division_factorizer(input i64) i64 {
	if input < -2_147_483_648 || input > 2_147_483_647 || input == 0 || input == -2_147_483_648 {
		return -1
	}
	number := if input < 0 { -input } else { input }
	mut divisor := i64(2)
	for divisor <= number / divisor {
		if number % divisor == 0 { return divisor }
		divisor++
	}
	return 0
}
