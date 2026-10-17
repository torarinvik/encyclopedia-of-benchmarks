package matrix_exponentiation

import "core:c"

MAX_ORDER :: 8
MAX_INPUT_WORDS :: 18
MOD :: i64(1_000_000_007)
MAX_N :: i64(1_000_000_000_000)

Matrix :: struct { cell: [MAX_ORDER][MAX_ORDER]i64 }

multiply :: proc(left, right: Matrix, order: int) -> Matrix {
	result := Matrix{}
	for row := 0; row < order; row += 1 {
		for col := 0; col < order; col += 1 {
			for inner := 0; inner < order; inner += 1 {
				result.cell[row][col] = (result.cell[row][col] + (left.cell[row][inner] * right.cell[inner][col]) % MOD) % MOD
			}
		}
	}
	return result
}
power :: proc(matrix: Matrix, exponent: i64, order: int) -> Matrix {
	if exponent == 1 do return matrix
	if exponent % 2 == 1 do return multiply(matrix, power(matrix, exponent - 1, order), order)
	half := power(matrix, exponent / 2, order)
	return multiply(half, half, order)
}

@(export)
matrix_exponentiation :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 1 || length > c.size_t(MAX_INPUT_WORDS) do return -1
	order_value := input[0]
	if order_value < 1 || order_value > MAX_ORDER || int(length) != int(2*order_value+2) do return -1
	order := int(order_value)
	for i := 0; i < 2*order; i += 1 { if input[1+i] < 0 || input[1+i] >= MOD do return -1 }
	n := input[2*order+1]
	if n < 0 || n > MAX_N do return -1
	if n == 0 do return 0
	if n <= order_value do return input[int(n)]
	transition: Matrix
	for i := 0; i < order-1; i += 1 { transition.cell[i][i+1] = 1 }
	for col := 0; col < order; col += 1 { transition.cell[order-1][col] = input[2*order-col] }
	transition = power(transition, n-1, order)
	result := i64(0)
	for i := 0; i < order; i += 1 { result = (result + (transition.cell[0][i] * input[1+i]) % MOD) % MOD }
	return result
}
