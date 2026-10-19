module matmul_f64_4x4

const max_iterations = i64(10000)
const matrix_elements = 16
const a = [16]f64{4.5, 1.3, 6.0, 4.1, 2.5, 7.2, 7.7, 1.7, 6.7, 1.3, 9.4, 1.3, 1.1, 2.2, 3.0, 2.1}
const b = [16]f64{1.0, 7.9, 5.1, 3.4, 6.6, 2.8, 5.4, 9.2, 5.0, 4.1, 4.1, 9.9, 8.4, 3.7, 9.5, 6.4}

@[export: 'matmul_f64_4x4']
pub fn matmul_f64_4x4(input &f64, input_length usize, mut output &f64, output_capacity usize) i64 {
	unsafe {
		if isnil(input) || input_length != 1 {
			return -1
		}
		requested := input[0]
		if requested != requested || requested < 1.0 || requested > f64(max_iterations) || f64(i64(requested)) != requested {
			return -1
		}
		iterations := i64(requested)
		mut staged := [matrix_elements]f64{}
		for _ in 0 .. int(iterations) {
			for row in 0 .. 4 {
				for column in 0 .. 4 {
					mut sum := a[row * 4] * b[column]
					sum += a[row * 4 + 1] * b[4 + column]
					sum += a[row * 4 + 2] * b[8 + column]
					sum += a[row * 4 + 3] * b[12 + column]
					staged[row * 4 + column] = sum
				}
			}
		}
		if isnil(output) || output_capacity < matrix_elements {
			return -2
		}
		for index in 0 .. matrix_elements {
			output[index] = staged[index]
		}
		return i64(matrix_elements)
	}
}
