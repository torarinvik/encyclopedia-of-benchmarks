package sparse_matrix_det

import "core:c"

MOD :: i64(998244353)
MAX_N :: 8
MAX_K :: 64
MAX_PARSEABLE :: 195

add_mod :: proc "contextless" (a, b: i64) -> i64 {
	value := a + b
	if value >= MOD do return value - MOD
	return value
}
sub_mod :: proc "contextless" (a, b: i64) -> i64 {
	value := a - b
	if value < 0 do return value + MOD
	return value
}
mul_mod :: proc "contextless" (a, b: i64) -> i64 { return a * b % MOD }
pow_mod :: proc "contextless" (value_value, exponent_value: i64) -> i64 {
	value, exponent := value_value, exponent_value
	result := i64(1)
	for exponent > 0 {
		if (exponent & 1) != 0 do result = mul_mod(result, value)
		value = mul_mod(value, value)
		exponent >>= 1
	}
	return result
}
next_residue :: proc "contextless" (state: ^i64) -> i64 {
	state^ = (state^ * 48271 + 1) % MOD
	return state^
}

berlekamp_massey :: proc "contextless" (sequence, connection: [^]i64, length: int) -> int {
	previous: [MAX_N + 1]i64
	temporary: [MAX_N + 1]i64
	for i := 0; i <= MAX_N; i += 1 {
		previous[i] = 0
		temporary[i] = 0
		connection[i] = 0
	}
	connection[0] = 1
	previous[0] = 1
	degree, shift, previous_degree := 0, 1, 0
	last_discrepancy := i64(1)
	for index := 0; index < length; index += 1 {
		discrepancy := sequence[index]
		for i := 1; i <= degree; i += 1 {
			discrepancy = add_mod(discrepancy, mul_mod(connection[i], sequence[index-i]))
		}
		if discrepancy == 0 {
			shift += 1
			continue
		}
		for i := 0; i <= MAX_N; i += 1 do temporary[i] = connection[i]
		scale := mul_mod(discrepancy, pow_mod(last_discrepancy, MOD-2))
		for i := 0; i <= previous_degree; i += 1 {
			target := i + shift
			if target <= MAX_N do connection[target] = sub_mod(connection[target], mul_mod(scale, previous[i]))
		}
		if 2*degree <= index {
			old_degree := degree
			degree = index + 1 - degree
			for i := 0; i <= MAX_N; i += 1 do previous[i] = temporary[i]
			previous_degree = old_degree
			last_discrepancy = discrepancy
			shift = 1
		} else {
			shift += 1
		}
	}
	return degree
}

dense_determinant :: proc "contextless" (row, column, entry: [^]i64, n, k: int) -> i64 {
	matrix: [MAX_N * MAX_N]i64
	for i := 0; i < MAX_N * MAX_N; i += 1 do matrix[i] = 0
	for e := 0; e < k; e += 1 do matrix[int(row[e])*MAX_N+int(column[e])] = entry[e]
	determinant := i64(1)
	for c := 0; c < n; c += 1 {
		pivot := c
		for pivot < n && matrix[pivot*MAX_N+c] == 0 do pivot += 1
		if pivot == n do return 0
		if pivot != c {
			for j := 0; j < n; j += 1 {
				temporary := matrix[c*MAX_N+j]
				matrix[c*MAX_N+j] = matrix[pivot*MAX_N+j]
				matrix[pivot*MAX_N+j] = temporary
			}
			determinant = MOD - determinant
		}
		pivot_value := matrix[c*MAX_N+c]
		determinant = mul_mod(determinant, pivot_value)
		inverse := pow_mod(pivot_value, MOD-2)
		for i := c + 1; i < n; i += 1 {
			if matrix[i*MAX_N+c] == 0 do continue
			factor := mul_mod(matrix[i*MAX_N+c], inverse)
			for j := c + 1; j < n; j += 1 do matrix[i*MAX_N+j] = sub_mod(matrix[i*MAX_N+j], mul_mod(factor, matrix[c*MAX_N+j]))
			matrix[i*MAX_N+c] = 0
		}
	}
	return determinant
}

sparse_wiedemann :: proc "contextless" (row, column, entry: [^]i64, n, k: int, seed_value: i64, success: ^bool) -> i64 {
	state := seed_value
	diagonal: [MAX_N]i64
	left: [MAX_N]i64
	vector: [MAX_N]i64
	next: [MAX_N]i64
	weighted: [MAX_N]i64
	sequence: [2*MAX_N]i64
	diagonal_product := i64(1)
	for i := 0; i < n; i += 1 {
		diagonal[i] = next_residue(&state)
		if diagonal[i] == 0 do diagonal[i] = 1
		left[i] = next_residue(&state)
		vector[i] = next_residue(&state)
		diagonal_product = mul_mod(diagonal_product, diagonal[i])
	}
	for step := 0; step < 2*n; step += 1 {
		dot := i64(0)
		for i := 0; i < n; i += 1 do dot = add_mod(dot, mul_mod(left[i], vector[i]))
		sequence[step] = dot
		for i := 0; i < n; i += 1 { weighted[i] = mul_mod(diagonal[i], vector[i]); next[i] = 0 }
		for e := 0; e < k; e += 1 {
			r, c := int(row[e]), int(column[e])
			next[r] = add_mod(next[r], mul_mod(entry[e], weighted[c]))
		}
		for i := 0; i < n; i += 1 do vector[i] = next[i]
	}
	connection: [MAX_N + 1]i64
	if berlekamp_massey(&sequence[0], &connection[0], 2*n) != n {
		success^ = false
		return 0
	}
	constant := connection[n]
	if (n & 1) != 0 && constant != 0 do constant = MOD - constant
	success^ = true
	return mul_mod(constant, pow_mod(diagonal_product, MOD-2))
}

store_i64_le :: proc "contextless" (output: [^]u8, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 { output[byte] = u8(bits & 255); bits >>= 8 }
}

@(export)
sparse_matrix_det :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > MAX_PARSEABLE do return -1
	n_value, k_value := input[0], input[1]
	if n_value < 1 || n_value > i64(MAX_N) || k_value < 1 || k_value > i64(MAX_K) do return -1
	n, k := int(n_value), int(k_value)
	if length != c.size_t(2 + 3*k) do return -1
	seen: [MAX_N * MAX_N]bool
	row: [MAX_K]i64
	column: [MAX_K]i64
	entry: [MAX_K]i64
	for i := 0; i < MAX_N*MAX_N; i += 1 do seen[i] = false
	for e := 0; e < k; e += 1 {
		r, c, value := input[2+3*e], input[3+3*e], input[4+3*e]
		if r < 0 || r >= n_value || c < 0 || c >= n_value || value < 1 || value >= MOD do return -1
		index := int(r)*MAX_N+int(c)
		if seen[index] do return -1
		seen[index] = true
		row[e] = r
		column[e] = c
		entry[e] = value
	}
	determinant := i64(0)
	found := false
	for attempt := 0; attempt < 4; attempt += 1 {
		seed := i64(104729 + attempt*1000003)
		if seed >= MOD do seed %= MOD
		determinant = sparse_wiedemann(&row[0], &column[0], &entry[0], n, k, seed, &found)
		if found do break
	}
	if !found do determinant = dense_determinant(&row[0], &column[0], &entry[0], n, k)
	if output == nil || capacity < 8 do return -2
	store_i64_le(output, determinant)
	return 8
}
