import math

const max_parseable_input_length = 19

fn exact_integer(value f64, low int, high int) ?int {
	if !value.is_finite() || value < f64(low) || value > f64(high) || f64(int(value)) != value { return none }
	return int(value)
}

@[export: 'lanczos_symmetric_tridiagonalization']
pub fn lanczos_symmetric_tridiagonalization(input &f64, input_length usize,
	mut output &f64, output_capacity usize) i64 {
	unsafe {
		if input == nil || input_length < 3 || input_length > max_parseable_input_length { return -1 }
		for index in 0 .. input_length { if !input[index].is_finite() { return -1 } }
		n := exact_integer(input[0], 1, 4) or { return -1 }
		k := exact_integer(input[1], 1, n) or { return -1 }
		if input_length != usize(2 + n * n) { return -1 }
		for row in 0 .. n {
			for col in 0 .. n {
				_ = exact_integer(input[2 + row*n + col], -4, 4) or { return -1 }
				if input[2 + row*n + col] != input[2 + col*n + row] { return -1 }
			}
		}
		required := 2 * k
		if output == nil || output_capacity < usize(required) { return -2 }
		mut previous := [4]f64{}
		mut current := [4]f64{}
		mut product := [4]f64{}
		mut residual := [4]f64{}
		mut next := [4]f64{}
		mut diagonal := [4]f64{}
		mut off_diagonal := [3]f64{}
		current[0] = 1.0
		mut previous_beta := 0.0
		for step in 0 .. k {
			for row in 0 .. n {
				product[row] = 0.0
				for col in 0 .. n { product[row] += input[2 + row*n + col] * current[col] }
			}
			mut alpha := 0.0
			for index in 0 .. n { alpha += current[index] * product[index] }
			if !alpha.is_finite() { return -3 }
			diagonal[step] = alpha
			if step + 1 == k { break }
			mut norm_squared := 0.0
			for index in 0 .. n {
				residual[index] = product[index] - alpha * current[index] - previous_beta * previous[index]
				norm_squared += residual[index] * residual[index]
			}
			if !norm_squared.is_finite() || norm_squared < 0.0 { return -3 }
			beta := math.sqrt(norm_squared)
			if !beta.is_finite() || beta <= 9.094947017729282e-13 { return -3 }
			off_diagonal[step] = beta
			for index in 0 .. n { next[index] = residual[index] / beta }
			for index in 0 .. n { previous[index] = current[index] }
			for index in 0 .. n { current[index] = next[index] }
			previous_beta = beta
		}
		output[0] = f64(k)
		for index in 0 .. k { output[1 + index] = diagonal[index] }
		for index in 0 .. k - 1 { output[1 + k + index] = off_diagonal[index] }
		return i64(required)
	}
}
