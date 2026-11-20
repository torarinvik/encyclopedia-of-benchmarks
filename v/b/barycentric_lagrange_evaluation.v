module barycentric_lagrange_evaluation

const modulus = i64(998244353)

fn bary_mod_pow(base_value i64, exponent_value i64) i64 {
	mut base := base_value
	mut exponent := exponent_value
	mut result := i64(1)
	for exponent > 0 {
		if (exponent & 1) != 0 { result = result * base % modulus }
		base = base * base % modulus
		exponent >>= 1
	}
	return result
}

@[export: 'barycentric_lagrange_evaluation']
pub fn barycentric_lagrange_evaluation(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 4 || length > 19 { return -1 }
		count_value := input[0]
		if count_value < 1 || count_value > 8 { return -1 }
		count := int(count_value)
		if int(length) != 2 * count + 2 { return -1 }
		for index in 1 .. int(length) {
			if input[index] < 0 || input[index] >= modulus { return -1 }
		}
		for left in 0 .. count {
			for right in 0 .. left {
				if input[1 + left] == input[1 + right] { return -1 }
			}
		}

		mut weights := [8]i64{}
		for index in 0 .. count {
			mut product := i64(1)
			node := input[1 + index]
			for other in 0 .. count {
				if other == index { continue }
				difference := (node - input[1 + other] + modulus) % modulus
				product = product * difference % modulus
			}
			weights[index] = bary_mod_pow(product, modulus - 2)
		}

		ordinate_start := 1 + count
		query := input[2 * count + 1]
		for index in 0 .. count {
			if query == input[1 + index] { return input[ordinate_start + index] }
		}
		mut numerator := i64(0)
		mut denominator := i64(0)
		for index in 0 .. count {
			difference := (query - input[1 + index] + modulus) % modulus
			term := weights[index] * bary_mod_pow(difference, modulus - 2) % modulus
			numerator = (numerator + term * input[ordinate_start + index]) % modulus
			denominator = (denominator + term) % modulus
		}
		if denominator == 0 { return -1 }
		return numerator * bary_mod_pow(denominator, modulus - 2) % modulus
	}
}
