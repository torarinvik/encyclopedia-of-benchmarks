package hensel_lifting_polynomial_root

import "core:c"

MAX_DEGREE :: 4
MAX_PRIME :: i64(43)
MAX_EXPONENT :: 6
MAX_MODULUS :: i64(100000)
MAX_LENGTH :: 10

normalized_mod :: proc(value, modulus: i64) -> i64 {
	result := value % modulus
	if result < 0 { result += modulus }
	return result
}

is_prime :: proc(value: i64) -> bool {
	if value < 2 do return false
	for divisor := i64(2); divisor*divisor <= value; divisor += 1 {
		if value % divisor == 0 do return false
	}
	return true
}

evaluate :: proc(input: [^]i64, degree: int, x, modulus: i64) -> i64 {
	result := i64(0)
	for index := degree; index >= 0; index -= 1 {
		result = normalized_mod(result*x+input[4+index], modulus)
	}
	return result
}

derivative :: proc(input: [^]i64, degree: int, x, prime: i64) -> i64 {
	result := i64(0)
	for index := degree; index >= 1; index -= 1 {
		result = normalized_mod(result*x+i64(index)*input[4+index], prime)
	}
	return result
}

@(export)
hensel_lifting_polynomial_root :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 6 || length > c.size_t(MAX_LENGTH) do return -1
	degree_value := input[0]
	prime := input[1]
	exponent := input[2]
	seed := input[3]
	if degree_value < 1 || degree_value > MAX_DEGREE || prime < 2 || prime > MAX_PRIME do return -1
	if exponent < 1 || exponent > MAX_EXPONENT || seed < 0 || seed >= prime do return -1
	degree := int(degree_value)
	if length != c.size_t(degree+5) || !is_prime(prime) do return -1
	for index := 0; index <= degree; index += 1 {
		if input[4+index] < -1000 || input[4+index] > 1000 do return -1
	}

	modulus := i64(1)
	for stage := i64(0); stage < exponent; stage += 1 {
		if modulus > MAX_MODULUS/prime do return -1
		modulus *= prime
	}
	if evaluate(input, degree, seed, prime) != 0 do return -1
	derivative_value := derivative(input, degree, seed, prime)
	if derivative_value == 0 do return -1
	inverse := i64(0)
	for candidate := i64(1); candidate < prime; candidate += 1 {
		if derivative_value*candidate % prime == 1 {
			inverse = candidate
			break
		}
	}
	if inverse == 0 do return -1

	root := seed
	power := prime
	for stage := i64(1); stage < exponent; stage += 1 {
		next_power := power*prime
		residue := evaluate(input, degree, root, next_power)
		quotient_digit := residue/power
		correction := normalized_mod(-quotient_digit*inverse, prime)
		root += correction*power
		power = next_power
	}
	return root
}
