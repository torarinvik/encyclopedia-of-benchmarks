module polynomial_root_finding

const modulus = i64(998244353)
const prng_modulus = i64(2147483647)
const max_n = 8
const max_input = 10
const max_product = 17

struct Polynomial {
	coefficients [max_product]i64
	degree int
}

fn normalize(value_input i64) i64 {
	mut value := value_input % modulus
	if value < 0 { value += modulus }
	return value
}

fn power_mod(base_input i64, exponent_input i64) i64 {
	mut base := base_input
	mut exponent := exponent_input
	mut result := i64(1)
	for exponent > 0 {
		if exponent & 1 != 0 { result = result * base % modulus }
		base = base * base % modulus
		exponent >>= 1
	}
	return result
}

fn zero_poly() Polynomial { return Polynomial{degree: -1} }

fn trim(mut polynomial Polynomial) {
	for polynomial.degree >= 0 && polynomial.coefficients[polynomial.degree] == 0 { polynomial.degree-- }
}

fn poly_mod(value_input Polynomial, divisor Polynomial) Polynomial {
	mut value := value_input
	if divisor.degree <= 0 || value.degree < 0 { return zero_poly() }
	inverse := power_mod(divisor.coefficients[divisor.degree], modulus - 2)
	for value.degree >= divisor.degree {
		shift := value.degree - divisor.degree
		factor := value.coefficients[value.degree] * inverse % modulus
		for i in 0 .. divisor.degree + 1 {
			value.coefficients[shift + i] = normalize(value.coefficients[shift + i] - factor * divisor.coefficients[i])
		}
		trim(mut value)
	}
	return value
}

fn multiply_mod(left Polynomial, right Polynomial, modulus_poly Polynomial) Polynomial {
	if left.degree < 0 || right.degree < 0 { return zero_poly() }
	mut product := [max_product]i64{}
	for i in 0 .. left.degree + 1 {
		for j in 0 .. right.degree + 1 {
			product[i + j] = (product[i + j] + left.coefficients[i] * right.coefficients[j]) % modulus
		}
	}
	mut expanded := zero_poly()
	expanded.degree = left.degree + right.degree
	for i in 0 .. expanded.degree + 1 { expanded.coefficients[i] = product[i] }
	trim(mut expanded)
	return poly_mod(expanded, modulus_poly)
}

fn polynomial_power_mod(base_input Polynomial, exponent_input i64, modulus_poly Polynomial) Polynomial {
	mut base := poly_mod(base_input, modulus_poly)
	mut exponent := exponent_input
	mut answer := zero_poly()
	answer.coefficients[0] = 1
	answer.degree = 0
	for exponent > 0 {
		if exponent & 1 != 0 { answer = multiply_mod(answer, base, modulus_poly) }
		base = multiply_mod(base, base, modulus_poly)
		exponent >>= 1
	}
	return answer
}

fn polynomial_gcd(left_input Polynomial, right_input Polynomial) Polynomial {
	mut left := left_input
	mut right := right_input
	for right.degree >= 0 {
		remainder := poly_mod(left, right)
		left = right
		right = remainder
	}
	if left.degree < 0 { return left }
	inverse := power_mod(left.coefficients[left.degree], modulus - 2)
	for i in 0 .. left.degree + 1 { left.coefficients[i] = left.coefficients[i] * inverse % modulus }
	return left
}

fn divide_exact(value_input Polynomial, divisor Polynomial) Polynomial {
	mut value := value_input
	mut quotient := zero_poly()
	quotient.degree = value.degree - divisor.degree
	if quotient.degree < 0 { return quotient }
	inverse := power_mod(divisor.coefficients[divisor.degree], modulus - 2)
	for value.degree >= divisor.degree {
		shift := value.degree - divisor.degree
		factor := value.coefficients[value.degree] * inverse % modulus
		quotient.coefficients[shift] = factor
		for i in 0 .. divisor.degree + 1 {
			value.coefficients[shift + i] = normalize(value.coefficients[shift + i] - factor * divisor.coefficients[i])
		}
		trim(mut value)
	}
	trim(mut quotient)
	return quotient
}

fn split_with_affine(polynomial Polynomial, slope i64, offset i64) (Polynomial, Polynomial, bool) {
	mut affine := zero_poly()
	affine.coefficients[0] = offset
	affine.coefficients[1] = slope
	affine.degree = 1
	affine = poly_mod(affine, polynomial)
	mut powered := polynomial_power_mod(affine, (modulus - 1) / 2, polynomial)
	if powered.degree < 0 {
		powered.coefficients[0] = modulus - 1
		powered.degree = 0
	} else { powered.coefficients[0] = normalize(powered.coefficients[0] - 1) }
	trim(mut powered)
	part := polynomial_gcd(polynomial, powered)
	if part.degree <= 0 || part.degree >= polynomial.degree { return zero_poly(), zero_poly(), false }
	return part, divide_exact(polynomial, part), true
}

fn collect_roots(polynomial Polynomial, mut roots [max_n]i64, mut root_count int, state_input i64) {
	if polynomial.degree == 1 {
		roots[root_count] = normalize(-polynomial.coefficients[0] * power_mod(polynomial.coefficients[1], modulus - 2))
		root_count++
		return
	}
	mut state := state_input
	for _ in 0 .. 32 {
		state = state * 48271 % prng_modulus
		mut slope := state % modulus
		if slope == 0 { slope = 1 }
		state = state * 48271 % prng_modulus
		offset := state % modulus
		first, second, success := split_with_affine(polynomial, slope, offset)
		if success {
			collect_roots(first, mut roots, mut root_count, state)
			collect_roots(second, mut roots, mut root_count, state + 1)
			return
		}
	}
	for offset in i64(0) .. modulus {
		first, second, success := split_with_affine(polynomial, 1, offset)
		if success {
			collect_roots(first, mut roots, mut root_count, state)
			collect_roots(second, mut roots, mut root_count, state + offset + 1)
			return
		}
	}
}

fn find_roots(polynomial Polynomial, mut roots [max_n]i64) int {
	if polynomial.degree <= 0 { return 0 }
	mut x := zero_poly()
	x.coefficients[1] = 1
	x.degree = 1
	x_mod := poly_mod(x, polynomial)
	mut x_to_p := polynomial_power_mod(x_mod, modulus, polynomial)
	largest := if x_to_p.degree > x_mod.degree { x_to_p.degree } else { x_mod.degree }
	for i in 0 .. largest + 1 {
		left := if i <= x_to_p.degree { x_to_p.coefficients[i] } else { i64(0) }
		right := if i <= x_mod.degree { x_mod.coefficients[i] } else { i64(0) }
		x_to_p.coefficients[i] = normalize(left - right)
	}
	x_to_p.degree = largest
	trim(mut x_to_p)
	linear_part := polynomial_gcd(polynomial, x_to_p)
	if linear_part.degree <= 0 { return 0 }
	mut seed := i64(1)
	for i in 0 .. polynomial.degree + 1 { seed = (seed * 31 + polynomial.coefficients[i]) % (prng_modulus - 1) + 1 }
	mut root_count := 0
	collect_roots(linear_part, mut roots, mut root_count, seed)
	for i in 0 .. root_count {
		for j in i + 1 .. root_count {
			if roots[j] < roots[i] { temporary := roots[i]; roots[i] = roots[j]; roots[j] = temporary }
		}
	}
	return root_count
}

fn store_le(mut output &u8, offset int, value i64) {
	mut bits := u64(value)
	for byte in 0 .. 8 { unsafe { output[offset + byte] = u8(bits & 255) }; bits >>= 8 }
}

@[export: 'polynomial_root_finding']
pub fn polynomial_root_finding(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > max_input { return -1 }
		if input[0] < 0 || input[0] > max_n || length != usize(input[0] + 2) { return -1 }
		mut polynomial := zero_poly()
		polynomial.degree = int(input[0])
		for i in 0 .. polynomial.degree + 1 {
			if input[i + 1] < 0 || input[i + 1] >= modulus { return -1 }
			polynomial.coefficients[i] = input[i + 1]
		}
		if polynomial.coefficients[polynomial.degree] == 0 { return -1 }
		mut roots := [max_n]i64{}
		root_count := find_roots(polynomial, mut roots)
		bytes := 8 * (root_count + 1)
		if output == nil || capacity < usize(bytes) { return -2 }
		store_le(mut output, 0, i64(root_count))
		for i in 0 .. root_count { store_le(mut output, 8 * (i + 1), roots[i]) }
		return i64(bytes)
	}
}
