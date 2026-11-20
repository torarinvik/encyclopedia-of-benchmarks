module cyclotomic_polynomial_coefficients

const cyclotomic_max_n = 32
const cyclotomic_max_input = usize(2)

fn cyclotomic_store_i64_le(mut output &u8, offset int, value i64) {
	bits := u64(value)
	unsafe {
		for byte in 0 .. 8 { output[offset + byte] = u8((bits >> u64(byte * 8)) & 255) }
	}
}

@[export: 'cyclotomic_polynomial_coefficients']
pub fn cyclotomic_polynomial_coefficients(input &i64, length usize, mut output &u8,
	capacity usize) i64 {
	unsafe {
		if input == nil || length == 0 || length > cyclotomic_max_input { return -1 }
		n_value := input[0]
		if n_value < 1 || n_value > cyclotomic_max_n || length != 1 { return -1 }
		n := int(n_value)

		mut polynomials := [33][33]i64{}
		mut degrees := [33]int{}
		polynomials[1][0] = -1
		polynomials[1][1] = 1
		degrees[1] = 1
		for k in 2 .. n + 1 {
			mut divisor := [33]i64{}
			divisor[0] = 1
			mut divisor_degree := 0
			for d in 1 .. k {
				if k % d != 0 { continue }
				mut product := [33]i64{}
				for i in 0 .. divisor_degree + 1 {
					for j in 0 .. degrees[d] + 1 {
						product[i + j] += divisor[i] * polynomials[d][j]
					}
				}
				divisor_degree += degrees[d]
				for i in 0 .. divisor_degree + 1 { divisor[i] = product[i] }
			}
			mut remainder := [33]i64{}
			remainder[0] = -1
			remainder[k] = 1
			quotient_degree := k - divisor_degree
			degrees[k] = quotient_degree
			for q in 0 .. quotient_degree + 1 {
				index := quotient_degree - q
				leading := remainder[divisor_degree + index]
				polynomials[k][index] = leading
				for j in 0 .. divisor_degree + 1 {
					remainder[index + j] -= leading * divisor[j]
				}
			}
		}

		coefficient_count := degrees[n] + 1
		required := usize(8 * coefficient_count)
		if output == nil || capacity < required { return -2 }
		for index in 0 .. coefficient_count {
			cyclotomic_store_i64_le(mut output, 8 * index, polynomials[n][index])
		}
		return i64(required)
	}
}
