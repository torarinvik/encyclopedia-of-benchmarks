module matrix_exponentiation

const max_order = 8
const max_input_words = 18
const mod = i64(1_000_000_007)
const max_n = i64(1_000_000_000_000)

struct Matrix {
	cell [max_order][max_order]i64
}

fn multiply(left Matrix, right Matrix, order int) Matrix {
	mut result := Matrix{}
	for row in 0 .. order {
		for col in 0 .. order {
			for inner in 0 .. order {
				result.cell[row][col] = (result.cell[row][col] + (left.cell[row][inner] * right.cell[inner][col]) % mod) % mod
			}
		}
	}
	return result
}
fn power(matrix Matrix, exponent i64, order int) Matrix {
	if exponent == 1 { return matrix }
	if exponent % 2 == 1 { return multiply(matrix, power(matrix, exponent - 1, order), order) }
	half := power(matrix, exponent / 2, order)
	return multiply(half, half, order)
}

@[export: 'matrix_exponentiation']
pub fn matrix_exponentiation(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 1 || length > max_input_words { return -1 }
		order_value := input[0]
		if order_value < 1 || order_value > max_order || int(length) != int(2 * order_value + 2) { return -1 }
		order := int(order_value)
		for i in 0 .. 2 * order { if input[1 + i] < 0 || input[1 + i] >= mod { return -1 } }
		n := input[2 * order + 1]
		if n < 0 || n > max_n { return -1 }
		if n == 0 { return 0 }
		if n <= order_value { return input[int(n)] }
		mut transition := Matrix{}
		for i in 0 .. order - 1 { transition.cell[i][i + 1] = 1 }
		for col in 0 .. order { transition.cell[order - 1][col] = input[2 * order - col] }
		transition = power(transition, n - 1, order)
		mut result := i64(0)
		for i in 0 .. order { result = (result + (transition.cell[0][i] * input[1 + i]) % mod) % mod }
		return result
	}
}
