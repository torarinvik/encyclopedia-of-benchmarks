module hensel_lifting_polynomial_root

const max_degree = 4
const max_prime = i64(43)
const max_exponent = 6
const max_modulus = i64(100000)
const max_length = 10

fn normalized_mod(value i64, modulus i64) i64 {
	mut result := value % modulus
	if result < 0 { result += modulus }
	return result
}

fn is_prime(value i64) bool {
	if value < 2 { return false }
	mut divisor := i64(2)
	for divisor * divisor <= value {
		if value % divisor == 0 { return false }
		divisor++
	}
	return true
}

fn evaluate(input &i64, degree int, x i64, modulus i64) i64 {
	mut result := i64(0)
	mut index := degree
	for index >= 0 {
		result = normalized_mod(result*x+input[4+index], modulus)
		index--
	}
	return result
}

fn derivative(input &i64, degree int, x i64, prime i64) i64 {
	mut result := i64(0)
	mut index := degree
	for index >= 1 {
		result = normalized_mod(result*x+i64(index)*input[4+index], prime)
		index--
	}
	return result
}

@[export: 'hensel_lifting_polynomial_root']
pub fn hensel_lifting_polynomial_root(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 6 || length > max_length { return -1 }
		degree_value := input[0]
		prime := input[1]
		exponent := input[2]
		seed := input[3]
		if degree_value < 1 || degree_value > max_degree || prime < 2 || prime > max_prime { return -1 }
		if exponent < 1 || exponent > max_exponent || seed < 0 || seed >= prime { return -1 }
		degree := int(degree_value)
		if length != usize(degree+5) || !is_prime(prime) { return -1 }
		for index in 0 .. degree + 1 {
			if input[4+index] < -1000 || input[4+index] > 1000 { return -1 }
		}

		mut modulus := i64(1)
		for _ in 0 .. int(exponent) {
			if modulus > max_modulus/prime { return -1 }
			modulus *= prime
		}
		if evaluate(input, degree, seed, prime) != 0 { return -1 }
		derivative_value := derivative(input, degree, seed, prime)
		if derivative_value == 0 { return -1 }
		mut inverse := i64(0)
		for candidate in i64(1) .. prime {
			if derivative_value*candidate % prime == 1 {
				inverse = candidate
				break
			}
		}
		if inverse == 0 { return -1 }

		mut root := seed
		mut power := prime
		for _ in 1 .. int(exponent) {
			next_power := power*prime
			residue := evaluate(input, degree, root, next_power)
			quotient_digit := residue/power
			correction := normalized_mod(-quotient_digit*inverse, prime)
			root += correction*power
			power = next_power
		}
		return root
	}
}
