module carmichael_number

fn is_composite(n i64) bool {
	if n < 4 { return false }
	mut divisor := i64(2)
	for divisor <= n / divisor {
		if n % divisor == 0 { return true }
		divisor++
	}
	return false
}

fn modular_power(base i64, exponent i64, modulus i64) i64 {
	mut result := i64(1)
	mut power := base
	mut remaining := exponent
	for remaining > 0 {
		if remaining % 2 != 0 { result = (result * power) % modulus }
		remaining /= 2
		if remaining > 0 { power = (power * power) % modulus }
	}
	return result
}

fn gcd(left_value i64, right_value i64) i64 {
	mut left := left_value
	mut right := right_value
	for right != 0 {
		remainder := left % right
		left = right
		right = remainder
	}
	return left
}

@[export: 'carmichael_number']
pub fn carmichael_number(value i64) i64 {
	if value < 1 || value > 10000 { return -1 }
	if value < 3 || !is_composite(value) { return 0 }
	mut base := i64(2)
	for base < value {
		if gcd(base, value) == 1 && modular_power(base, value - 1, value) != 1 { return 0 }
		base++
	}
	return 1
}
