module sparse_matrix_det

const modulus = i64(998244353)
const max_n = 8
const max_k = 64
const max_parseable_input = 195

fn add_mod(a i64, b i64) i64 {
	value := a + b
	return if value >= modulus { value - modulus } else { value }
}
fn sub_mod(a i64, b i64) i64 {
	value := a - b
	return if value < 0 { value + modulus } else { value }
}
fn mul_mod(a i64, b i64) i64 { return a * b % modulus }
fn pow_mod(value_value i64, exponent_value i64) i64 {
	mut value := value_value
	mut exponent := exponent_value
	mut result := i64(1)
	for exponent > 0 {
		if exponent & 1 != 0 { result = mul_mod(result, value) }
		value = mul_mod(value, value)
		exponent >>= 1
	}
	return result
}
fn next_residue(mut state i64) i64 {
	state = (state * 48271 + 1) % modulus
	return state
}

fn berlekamp_massey(sequence []i64, length int, mut connection []i64) int {
	mut previous := []i64{len: max_n + 1}
	mut temporary := []i64{len: max_n + 1}
	for i in 0 .. max_n + 1 { connection[i] = 0 }
	connection[0] = 1
	previous[0] = 1
	mut degree := 0
	mut shift := 1
	mut previous_degree := 0
	mut last_discrepancy := i64(1)
	for index in 0 .. length {
		mut discrepancy := sequence[index]
		for i in 1 .. degree + 1 {
			discrepancy = add_mod(discrepancy, mul_mod(connection[i], sequence[index - i]))
		}
		if discrepancy == 0 { shift++; continue }
		for i in 0 .. max_n + 1 { temporary[i] = connection[i] }
		scale := mul_mod(discrepancy, pow_mod(last_discrepancy, modulus - 2))
		for i in 0 .. previous_degree + 1 {
			target := i + shift
			if target <= max_n { connection[target] = sub_mod(connection[target], mul_mod(scale, previous[i])) }
		}
		if 2 * degree <= index {
			old_degree := degree
			degree = index + 1 - degree
			for i in 0 .. max_n + 1 { previous[i] = temporary[i] }
			previous_degree = old_degree
			last_discrepancy = discrepancy
			shift = 1
		} else { shift++ }
	}
	return degree
}

fn dense_determinant(row []int, column []int, entry []i64, n int, k int) i64 {
	mut matrix := []i64{len: max_n * max_n}
	for e in 0 .. k { matrix[row[e] * max_n + column[e]] = entry[e] }
	mut determinant := i64(1)
	for c in 0 .. n {
		mut pivot := c
		for pivot < n && matrix[pivot * max_n + c] == 0 { pivot++ }
		if pivot == n { return 0 }
		if pivot != c {
			for j in 0 .. n {
				temporary := matrix[c * max_n + j]
				matrix[c * max_n + j] = matrix[pivot * max_n + j]
				matrix[pivot * max_n + j] = temporary
			}
			determinant = modulus - determinant
		}
		pivot_value := matrix[c * max_n + c]
		determinant = mul_mod(determinant, pivot_value)
		inverse := pow_mod(pivot_value, modulus - 2)
		for i in c + 1 .. n {
			if matrix[i * max_n + c] == 0 { continue }
			factor := mul_mod(matrix[i * max_n + c], inverse)
			for j in c + 1 .. n {
				matrix[i * max_n + j] = sub_mod(matrix[i * max_n + j], mul_mod(factor, matrix[c * max_n + j]))
			}
			matrix[i * max_n + c] = 0
		}
	}
	return determinant
}

fn sparse_wiedemann(row []int, column []int, entry []i64, n int, k int, seed_value i64, mut connection []i64) ?i64 {
	mut state := seed_value
	mut diagonal := []i64{len: max_n}
	mut left := []i64{len: max_n}
	mut vector := []i64{len: max_n}
	mut next := []i64{len: max_n}
	mut weighted := []i64{len: max_n}
	mut sequence := []i64{len: 2 * max_n}
	mut diagonal_product := i64(1)
	for i in 0 .. n {
		diagonal[i] = next_residue(mut state)
		if diagonal[i] == 0 { diagonal[i] = 1 }
		left[i] = next_residue(mut state)
		vector[i] = next_residue(mut state)
		diagonal_product = mul_mod(diagonal_product, diagonal[i])
	}
	for step in 0 .. 2 * n {
		mut dot := i64(0)
		for i in 0 .. n { dot = add_mod(dot, mul_mod(left[i], vector[i])) }
		sequence[step] = dot
		for i in 0 .. n { weighted[i] = mul_mod(diagonal[i], vector[i]); next[i] = 0 }
		for e in 0 .. k {
			index := row[e]
			next[index] = add_mod(next[index], mul_mod(entry[e], weighted[column[e]]))
		}
		for i in 0 .. n { vector[i] = next[i] }
	}
	degree := berlekamp_massey(sequence, 2 * n, mut connection)
	if degree != n { return none }
	mut constant := connection[n]
	if n & 1 != 0 && constant != 0 { constant = modulus - constant }
	return mul_mod(constant, pow_mod(diagonal_product, modulus - 2))
}

fn store_i64_le(mut output &u8, value i64) {
	mut bits := u64(value)
	unsafe {
		for byte in 0 .. 8 { output[byte] = u8(bits & 255); bits >>= 8 }
	}
}

@[export: 'sparse_matrix_det']
pub fn sparse_matrix_det(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 2 || length > max_parseable_input { return -1 }
	n_value := unsafe { input[0] }
	k_value := unsafe { input[1] }
	if n_value < 1 || n_value > max_n || k_value < 1 || k_value > max_k { return -1 }
	n := int(n_value)
	k := int(k_value)
	if length != usize(2 + 3 * k) { return -1 }
	mut seen := []bool{len: max_n * max_n}
	mut row := []int{len: max_k}
	mut column := []int{len: max_k}
	mut entry := []i64{len: max_k}
	for e in 0 .. k {
		r := unsafe { input[2 + 3 * e] }
		c := unsafe { input[3 + 3 * e] }
		value := unsafe { input[4 + 3 * e] }
		if r < 0 || r >= n_value || c < 0 || c >= n_value || value < 1 || value >= modulus { return -1 }
		index := int(r) * max_n + int(c)
		if seen[index] { return -1 }
		seen[index] = true
		row[e] = int(r)
		column[e] = int(c)
		entry[e] = value
	}
	mut determinant := i64(0)
	mut found := false
	mut connection := []i64{len: max_n + 1}
	for attempt in 0 .. 4 {
		mut seed := i64(104729 + attempt * 1000003)
		if seed >= modulus { seed %= modulus }
		candidate := sparse_wiedemann(row, column, entry, n, k, seed, mut connection) or { continue }
		determinant = candidate
		found = true
		break
	}
	if !found { determinant = dense_determinant(row, column, entry, n, k) }
	if unsafe { output == nil } || capacity < 8 { return -2 }
	store_i64_le(mut output, determinant)
	return 8
}
