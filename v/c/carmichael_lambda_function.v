// Carmichael's universal exponent by prime-power factorization.
module carmichael_lambda_function

const max_n = i64(1024)
const max_parseable_length = 2

fn gcd_i64(left_value i64, right_value i64) i64 {
	mut left := left_value
	mut right := right_value
	for right != 0 {
		remainder := left % right
		left = right
		right = remainder
	}
	return left
}

fn lcm_i64(left i64, right i64) i64 {
	return left / gcd_i64(left, right) * right
}

fn prime_power_lambda(prime i64, exponent int, power i64) i64 {
	if prime == 2 {
		if exponent == 1 { return 1 }
		if exponent == 2 { return 2 }
		return power / 4
	}
	return (power / prime) * (prime - 1)
}

fn factorization_lambda(n i64) i64 {
	if n == 1 { return 1 }
	mut remaining := n
	mut result := i64(1)
	mut prime := i64(2)
	for prime * prime <= remaining {
		if remaining % prime != 0 {
			if prime == 2 { prime = 3 } else { prime += 2 }
			continue
		}
		mut exponent := 0
		mut power := i64(1)
		for remaining % prime == 0 {
			remaining /= prime
			power *= prime
			exponent++
		}
		result = lcm_i64(result, prime_power_lambda(prime, exponent, power))
		if prime == 2 { prime = 3 } else { prime += 2 }
	}
	if remaining > 1 { result = lcm_i64(result, remaining - 1) }
	return result
}

@[export: 'carmichael_lambda_function']
pub fn carmichael_lambda_function(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 1 || length > max_parseable_length { return -1 }
		n := input[0]
		if n < 1 || n > max_n || length != 1 { return -1 }
		return factorization_lambda(n)
	}
}
