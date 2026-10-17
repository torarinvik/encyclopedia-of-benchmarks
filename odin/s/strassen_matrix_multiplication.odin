package strassen_matrix_multiplication

import "core:c"

MAX_INPUT_LENGTH :: 129

strassen_multiply :: proc(a, b, result: [^]i64, n: int) {
	if n == 1 { result[0] = a[0] * b[0]; return }
	h := n / 2
	x: [16]i64
	y: [16]i64
	m1: [16]i64
	m2: [16]i64
	m3: [16]i64
	m4: [16]i64
	m5: [16]i64
	m6: [16]i64
	m7: [16]i64
	for r := 0; r < h; r += 1 { for col := 0; col < h; col += 1 {
		i := r * h + col
		x[i] = a[r*n+col] + a[(r+h)*n+col+h]
		y[i] = b[r*n+col] + b[(r+h)*n+col+h]
	} }
	strassen_multiply(&x[0], &y[0], &m1[0], h)
	for r := 0; r < h; r += 1 { for col := 0; col < h; col += 1 {
		i := r * h + col
		x[i] = a[(r+h)*n+col] + a[(r+h)*n+col+h]; y[i] = b[r*n+col]
	} }
	strassen_multiply(&x[0], &y[0], &m2[0], h)
	for r := 0; r < h; r += 1 { for col := 0; col < h; col += 1 {
		i := r * h + col
		x[i] = a[r*n+col]; y[i] = b[r*n+col+h] - b[(r+h)*n+col+h]
	} }
	strassen_multiply(&x[0], &y[0], &m3[0], h)
	for r := 0; r < h; r += 1 { for col := 0; col < h; col += 1 {
		i := r * h + col
		x[i] = a[(r+h)*n+col+h]; y[i] = b[(r+h)*n+col] - b[r*n+col]
	} }
	strassen_multiply(&x[0], &y[0], &m4[0], h)
	for r := 0; r < h; r += 1 { for col := 0; col < h; col += 1 {
		i := r * h + col
		x[i] = a[r*n+col] + a[r*n+col+h]; y[i] = b[(r+h)*n+col+h]
	} }
	strassen_multiply(&x[0], &y[0], &m5[0], h)
	for r := 0; r < h; r += 1 { for col := 0; col < h; col += 1 {
		i := r * h + col
		x[i] = a[(r+h)*n+col] - a[r*n+col]; y[i] = b[r*n+col] + b[r*n+col+h]
	} }
	strassen_multiply(&x[0], &y[0], &m6[0], h)
	for r := 0; r < h; r += 1 { for col := 0; col < h; col += 1 {
		i := r * h + col
		x[i] = a[r*n+col+h] - a[(r+h)*n+col+h]
		y[i] = b[(r+h)*n+col] + b[(r+h)*n+col+h]
	} }
	strassen_multiply(&x[0], &y[0], &m7[0], h)
	for r := 0; r < h; r += 1 { for col := 0; col < h; col += 1 {
		i := r * h + col
		result[r*n+col] = m1[i] + m4[i] - m5[i] + m7[i]
		result[r*n+col+h] = m3[i] + m5[i]
		result[(r+h)*n+col] = m2[i] + m4[i]
		result[(r+h)*n+col+h] = m1[i] - m2[i] + m3[i] + m6[i]
	} }
}

@(export, link_name="strassen_matrix_multiplication")
strassen_matrix_multiplication :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 1 || length > c.size_t(MAX_INPUT_LENGTH) do return -1
	n_arg := input[0]
	if n_arg != 1 && n_arg != 2 && n_arg != 4 && n_arg != 8 do return -1
	n := int(n_arg)
	cells := n * n
	if length != c.size_t(1 + 2*cells) do return -1
	for i := 0; i < 2*cells; i += 1 { if input[1+i] < -2 || input[1+i] > 2 do return -1 }
	output_bytes := c.size_t(8 * cells)
	if output == nil || capacity < output_bytes do return -2
	result: [64]i64
	strassen_multiply(&input[1], &input[1+cells], &result[0], n)
	for i := 0; i < cells; i += 1 {
		bits := transmute(u64)(result[i])
		for byte := 0; byte < 8; byte += 1 { output[i*8+byte] = u8((bits >> (8*byte)) & 255) }
	}
	return i64(output_bytes)
}
