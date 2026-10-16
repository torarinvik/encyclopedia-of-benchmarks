package matrix_exponentiation_recursive

import "core:c"

Matrix2 :: [4]i64
multiply :: proc(a, b: Matrix2) -> Matrix2 {
	var c: Matrix2
	for r := 0; r < 2; r += 1 { for col := 0; col < 2; col += 1 { for k := 0; k < 2; k += 1 { c[r*2+col] += a[r*2+k] * b[k*2+col] } } }
	return c
}
power :: proc(a: Matrix2, e: i64) -> Matrix2 {
	if e == 0 do return Matrix2{1, 0, 0, 1}
	if e % 2 == 1 do return multiply(power(a, e-1), a)
	half := power(a, e/2)
	return multiply(half, half)
}
store_i64_le :: proc "contextless" (out: [^]u8, offset: int, value: i64) {
	bits := transmute(u64)value
	for b := 0; b < 8; b += 1 { out[offset+b] = u8(bits >> u64(8*b)) }
}
@(export)
matrix_exponentiation_recursive :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length != 5 do return -2
	if input[0] < 0 || input[0] > 30 do return -2
	for i := 1; i < 5; i += 1 { if input[i] < -1 || input[i] > 1 do return -2 }
	if output == nil || capacity < 32 do return -3
	result := power(Matrix2{input[1], input[2], input[3], input[4]}, input[0])
	for i := 0; i < 4; i += 1 { store_i64_le(output, i*8, result[i]) }
	return 4
}
