package pade_approximant_series_coefficients

import "core:c"

MODULUS :: i64(998244353)
MAX_INPUT_LENGTH :: 12

mod_pow :: proc(base_value, exponent_value: i64) -> i64 {
	base, exponent, result := base_value, exponent_value, i64(1)
	for exponent > 0 {
		if (exponent & 1) != 0 do result = result * base % MODULUS
		base = base * base % MODULUS
		exponent >>= 1
	}
	return result
}

store_i64_le :: proc(output: [^]u8, offset: c.size_t, value: i64) {
	bits := transmute(u64)value
	for byte := c.size_t(0); byte < 8; byte += 1 {
		output[offset+byte] = u8(bits & 255)
		bits >>= 8
	}
}

@(export)
pade_approximant_series_coefficients :: proc "c" (input: [^]i64,
	length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 5 || length > MAX_INPUT_LENGTH do return -1
	pv, qv := input[0], input[1]
	if qv < 1 || pv < qv || pv > 4 || qv > 4 || length != c.size_t(pv+qv+3) do return -1
	p, q := int(pv), int(qv)
	mut coefficients: [9]u32 = {}
	for i := 0; i <= p+q; i += 1 {
		if input[i+2] < 0 || input[i+2] >= MODULUS do return -1
		coefficients[i] = u32(input[i+2])
	}
	required := c.size_t(8*(p+q+4))
	if output == nil || capacity < required do return -2

	mut matrix: [4][5]u32 = {}
	for row := 0; row < q; row += 1 {
		m := p+1+row
		for col := 0; col < q; col += 1 do matrix[row][col] = coefficients[m-col-1]
		matrix[row][q] = u32((MODULUS-i64(coefficients[m]))%MODULUS)
	}
	for col := 0; col < q; col += 1 {
		mut pivot := col
		for pivot < q && matrix[pivot][col] == 0 do pivot += 1
		if pivot == q do return -3
		if pivot != col {
			for j := 0; j <= q; j += 1 {
				matrix[col][j], matrix[pivot][j] = matrix[pivot][j], matrix[col][j]
			}
		}
		inverse := mod_pow(i64(matrix[col][col]), MODULUS-2)
		for j := col; j <= q; j += 1 do matrix[col][j] = u32(i64(matrix[col][j])*inverse%MODULUS)
		for row := 0; row < q; row += 1 {
			if row == col do continue
			factor := i64(matrix[row][col])
			for j := col; j <= q; j += 1 {
				product := factor*i64(matrix[col][j])%MODULUS
				mut difference := i64(matrix[row][j])-product
				if difference < 0 do difference += MODULUS
				matrix[row][j] = u32(difference)
			}
		}
	}
	store_i64_le(output,0,pv)
	store_i64_le(output,8,qv)
	mut offset := c.size_t(16)
	for m := 0; m <= p; m += 1 {
		mut value := u64(coefficients[m])
		last := if m < q do m else q
		for j := 1; j <= last; j += 1 {
			value = (value+u64(coefficients[m-j])*u64(matrix[j-1][q]))%u64(MODULUS)
		}
		store_i64_le(output,offset,i64(value))
		offset += 8
	}
	store_i64_le(output,offset,1)
	offset += 8
	for j := 0; j < q; j += 1 {
		store_i64_le(output,offset,i64(matrix[j][q]))
		offset += 8
	}
	return i64(required)
}
