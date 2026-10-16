package trial_division_factorizer

@(export)
trial_division_factorizer :: proc "c" (input: i64) -> i64 {
	if input < -2_147_483_648 || input > 2_147_483_647 || input == 0 || input == -2_147_483_648 do return -1
	number := if input < 0 { -input } else { input }
	for divisor := i64(2); divisor <= number / divisor; divisor += 1 {
		if number % divisor == 0 do return divisor
	}
	return 0
}
