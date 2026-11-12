module characteristic_polynomial

const modulus = i64(998244353)
const max_n = 8
const max_input_values = 1 + max_n * max_n + 1

fn normalize(value i64) i64 {
	result := value % modulus
	return if result < 0 { result + modulus } else { result }
}

fn multiply(left i64, right i64) i64 {
	return (left * right) % modulus
}

fn power(base_value i64, exponent_value i64) i64 {
	mut base := base_value
	mut exponent := exponent_value
	mut result := i64(1)
	for exponent > 0 {
		if (exponent & 1) != 0 { result = multiply(result, base) }
		base = multiply(base, base)
		exponent >>= 1
	}
	return result
}

fn store_i64_le(mut output &u8, value i64) {
	mut bits := u64(value)
	unsafe {
		for byte in 0 .. 8 {
			output[byte] = u8(bits & 255)
			bits >>= 8
		}
	}
}

@[export: 'characteristic_polynomial']
pub fn characteristic_polynomial(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 1 || length > max_input_values { return -1 }
	n_value := unsafe { input[0] }
	if n_value < 0 || n_value > max_n { return -1 }
	n := int(n_value)
	if length != usize(1 + n * n) { return -1 }

	mut matrix := []i64{len: max_n * max_n}
	for row in 0 .. n {
		for column in 0 .. n {
			value := unsafe { input[1 + row * n + column] }
			if value < 0 || value >= modulus { return -1 }
			matrix[row * max_n + column] = value
		}
	}

	for column in 0 .. n {
		if column + 2 >= n { break }
		mut pivot := column + 1
		for pivot < n && matrix[pivot * max_n + column] == 0 { pivot++ }
		if pivot == n { continue }
		if pivot != column + 1 {
			for k in 0 .. n {
				matrix[(column + 1) * max_n + k], matrix[pivot * max_n + k] = matrix[pivot * max_n + k], matrix[(column + 1) * max_n + k]
			}
			for row in 0 .. n {
				matrix[row * max_n + column + 1], matrix[row * max_n + pivot] = matrix[row * max_n + pivot], matrix[row * max_n + column + 1]
			}
		}
		inverse := power(matrix[(column + 1) * max_n + column], modulus - 2)
		for row in column + 2 .. n {
			if matrix[row * max_n + column] == 0 { continue }
			factor := multiply(matrix[row * max_n + column], inverse)
			for k in 0 .. n {
				matrix[row * max_n + k] = normalize(
					matrix[row * max_n + k] - multiply(factor, matrix[(column + 1) * max_n + k]))
			}
			for k in 0 .. n {
				matrix[k * max_n + column + 1] = normalize(
					matrix[k * max_n + column + 1] + multiply(factor, matrix[k * max_n + row]))
			}
		}
	}

	mut coefficients := []i64{len: (max_n + 1) * (max_n + 1)}
	coefficients[0] = 1
	for size in 1 .. n + 1 {
		for degree in 0 .. size + 1 {
			mut value := i64(0)
			if degree > 0 { value = coefficients[(size - 1) * (max_n + 1) + degree - 1] }
			if degree < size {
				value -= multiply(matrix[(size - 1) * max_n + size - 1], coefficients[(size - 1) * (max_n + 1) + degree])
			}
			coefficients[size * (max_n + 1) + degree] = normalize(value)
		}
		mut subdiagonal_product := i64(1)
		mut start := size - 2
		for start >= 0 {
			subdiagonal_product = multiply(subdiagonal_product, matrix[(start + 1) * max_n + start])
			term := multiply(subdiagonal_product, matrix[start * max_n + size - 1])
			for degree in 0 .. start + 1 {
				coefficients[size * (max_n + 1) + degree] = normalize(
					coefficients[size * (max_n + 1) + degree] - multiply(term, coefficients[start * (max_n + 1) + degree]))
			}
			start--
		}
	}

	output_bytes := 8 * (n + 1)
	if unsafe { output == nil } || capacity < output_bytes { return -2 }
	for degree in 0 .. n + 1 {
		store_i64_le(mut output[8 * degree], coefficients[n * (max_n + 1) + degree])
	}
	return i64(output_bytes)
}
