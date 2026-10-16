module binomial_expansion

const max_exponent = 31
const invalid_result = i64(-9223372036854775808)

fn integer_power(base i64, exponent i64) i64 {
	mut result := i64(1)
	for _ in 0 .. int(exponent) { result *= base }
	return result
}

fn binomial_coefficient(n i64, k i64) i64 {
	mut coefficients := [32]i64{init: 0}
	coefficients[0] = 1
	for row in 1 .. int(n) + 1 {
		mut column := if row < int(k) { row } else { int(k) }
		for column > 0 {
			coefficients[column] += coefficients[column - 1]
			column--
		}
	}
	return coefficients[int(k)]
}

@[export: 'binomial_expansion']
pub fn binomial_expansion(values &i64, length usize) i64 {
	unsafe {
		if isnil(values) || length != 3 { return invalid_result }
		a := values[0]
		b := values[1]
		exponent := values[2]
		if a < -2 || a > 2 || b < -2 || b > 2 || exponent < 0 || exponent > max_exponent { return invalid_result }
		mut result := i64(0)
		for index in 0 .. int(exponent) + 1 {
			result += binomial_coefficient(exponent, i64(index)) *
				integer_power(a, exponent - i64(index)) * integer_power(b, i64(index))
		}
		return result
	}
}
