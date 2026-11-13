module pollard_p_minus_one_factorization

const small_primes = [18]i64{2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53, 59, 61}

fn gcd_i64(left_input i64, right_input i64) i64 {
	mut left := left_input
	mut right := right_input
	for right != 0 {
		remainder := left % right
		left = right
		right = remainder
	}
	return left
}

fn pow_mod_i64(base_input i64, exponent_input i64, modulus i64) i64 {
	mut result := i64(1)
	mut base := base_input % modulus
	mut exponent := exponent_input
	for exponent > 0 {
		if (exponent & 1) != 0 { result = (result * base) % modulus }
		base = (base * base) % modulus
		exponent >>= 1
	}
	return result
}

@[export: 'pollard_p_minus_one_factorization']
pub fn pollard_p_minus_one_factorization(input &i64, length usize) i64 {
	if unsafe { input == nil } || length != 3 { return -1 }
	unsafe {
		number, bound, initial := input[0], input[1], input[2]
		if number < 2 || number > 1_000_000_000 || bound < 2 || bound > 64 || initial < 1 || initial >= number { return -1 }
		mut divisor := gcd_i64(initial, number)
		if divisor > 1 { return divisor }
		mut state := initial
		for prime in small_primes {
			if prime > bound { break }
			mut exponent := prime
			for exponent <= bound / prime { exponent *= prime }
			state = pow_mod_i64(state, exponent, number)
			mut difference := state - 1
			if difference < 0 { difference = -difference }
			divisor = gcd_i64(difference, number)
			if divisor > 1 { return if divisor < number { divisor } else { i64(0) } }
		}
		return 0
	}
}
