module chernick_carmichael_least_multiplier

const max_multiplier = i64(950560)

fn is_prime(value i64) bool {
	if value < 2 { return false }
	mut divisor := i64(2)
	for divisor <= value / divisor {
		if value % divisor == 0 { return false }
		divisor++
	}
	return true
}

fn all_chernick_factors_are_prime(n i64, multiplier i64) bool {
	if !is_prime(6 * multiplier + 1) || !is_prime(12 * multiplier + 1) {
		return false
	}

	mut factor := 18 * multiplier + 1
	mut index := i64(1)
	for index <= n - 2 {
		if !is_prime(factor) { return false }
		if index < n - 2 { factor = 2 * (factor - 1) + 1 }
		index++
	}
	return true
}

@[export: 'chernick_carmichael_least_multiplier']
pub fn chernick_carmichael_least_multiplier(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length != 1 { return -1 }
		n := input[0]
		if n < 3 || n > 9 { return -1 }

		mut step := i64(1)
		mut shift_count := i64(0)
		if n > 4 { shift_count = n - 4 }
		for shift_count > 0 {
			step *= 2
			shift_count--
		}
		if n > 5 { step *= 5 }

		mut multiplier := step
		for multiplier <= max_multiplier {
			if all_chernick_factors_are_prime(n, multiplier) { return multiplier }
			multiplier += step
		}
		return -1
	}
}
