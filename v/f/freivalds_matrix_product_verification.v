module freivalds_matrix_product_verification
import core.c

const max_n = 8
const max_rounds = 8
const max_input = 259

@[export: 'freivalds_matrix_product_verification']
pub fn freivalds_matrix_product_verification(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > max_input { return -1 }
		n64, rounds64 := input[0], input[1]
		if n64 < 1 || n64 > 8 || rounds64 < 1 || rounds64 > 8 { return -1 }
		n, rounds := int(n64), int(rounds64)
		matrix_words := n * n
		if length != usize(2 + 3 * matrix_words + rounds * n) { return -1 }
		for word in 2 .. 2 + 3 * matrix_words {
			if input[word] < -3 || input[word] > 3 { return -1 }
		}
		signs_offset := 2 + 3 * matrix_words
		for word in signs_offset .. int(length) {
			if input[word] != -1 && input[word] != 1 { return -1 }
		}
		mut bx := []i64{len: max_n, init: 0}
		mut abx := []i64{len: max_n, init: 0}
		mut cx := []i64{len: max_n, init: 0}
		for round in 0 .. rounds {
			for row in 0 .. n {
				mut sum := i64(0)
				for col in 0 .. n {
					sum += input[2 + matrix_words + row * n + col] * input[signs_offset + round * n + col]
				}
				bx[row] = sum
			}
			for row in 0 .. n {
				mut left := i64(0)
				mut right := i64(0)
				for col in 0 .. n {
					left += input[2 + row * n + col] * bx[col]
					right += input[2 + 2 * matrix_words + row * n + col] * input[signs_offset + round * n + col]
				}
				abx[row], cx[row] = left, right
			}
			for row in 0 .. n { if abx[row] != cx[row] { return 0 } }
		}
		return 1
	}
}
