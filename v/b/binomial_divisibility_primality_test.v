module binomial_divisibility_primality_test

const max_n = i64(1000)

@[export: 'binomial_divisibility_primality_test']
pub fn binomial_divisibility_primality_test(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length != 1 { return -1 }
		value := input[0]
		if value < 2 || value > max_n { return -1 }

		n := int(value)
		mut coefficients := [1001]i64{}
		coefficients[0] = 1
		for degree in 1 .. n + 1 {
			coefficients[degree] = 1
			mut column := degree - 1
			for column > 0 {
				coefficients[column] = (coefficients[column] + coefficients[column - 1]) % value
				column--
			}
		}

		for column in 1 .. n {
			if coefficients[column] != 0 { return 0 }
		}
		return 1
	}
}
