import math

@[export: 'qr_eigen_values']
pub fn qr_eigen_values(input &f64, input_length usize, mut output &f64, capacity usize) i64 {
	unsafe {
		if input == nil || input_length != 5 || input[0] != 2 { return -1 }
		mut matrix := [4]f64{}
		for i in 0 .. 4 {
			value := input[i + 1]
			if !value.is_finite() || value < -9 || value > 9 || math.floor(value) != value { return -1 }
			matrix[i] = value
		}
		if matrix[1] != matrix[2] || matrix[1] == 0 || matrix[0] == matrix[3] { return -1 }
		mut last_eigenvalue := 0.0
		mut iterations := 0
		for math.abs(matrix[2]) > 1e-10 {
			if iterations >= 256 { return -1 }
			last_eigenvalue = matrix[3]
			mut shifted := matrix
			shifted[0] -= last_eigenvalue
			shifted[3] -= last_eigenvalue
			mut q := [4]f64{}
			mut r := [4]f64{}
			for column in 0 .. 2 {
				mut original := [2]f64{}
				mut residual := [2]f64{}
				for row in 0 .. 2 {
					original[row] = shifted[row * 2 + column]
					residual[row] = original[row]
				}
				for previous in 0 .. column {
					mut basis := [2]f64{}
					for row in 0 .. 2 { basis[row] = q[row * 2 + previous] }
					mut denominator := 0.0
					for row in 0 .. 2 { denominator += basis[row] * basis[row] }
					if denominator == 0 || !denominator.is_finite() { return -1 }
					mut dot := 0.0
					for row in 0 .. 2 { dot += original[row] * basis[row] }
					scalar := dot / denominator
					for row in 0 .. 2 { residual[row] -= scalar * basis[row] }
				}
				mut norm_squared := 0.0
				for row in 0 .. 2 { norm_squared += residual[row] * residual[row] }
				norm := math.sqrt(norm_squared)
				if norm == 0 || !norm.is_finite() { return -1 }
				for row in 0 .. 2 { q[row * 2 + column] = residual[row] / norm }
				for target in column .. 2 {
					mut dot := 0.0
					for row in 0 .. 2 { dot += q[row * 2 + column] * shifted[row * 2 + target] }
					r[column * 2 + target] = dot
				}
			}
			mut updated := [4]f64{}
			for row in 0 .. 2 {
				for column in 0 .. 2 {
					for inner in 0 .. 2 { updated[row * 2 + column] += r[row * 2 + inner] * q[inner * 2 + column] }
				}
			}
			updated[0] += last_eigenvalue
			updated[3] += last_eigenvalue
			for i in 0 .. 4 {
				if !updated[i].is_finite() { return -1 }
				matrix[i] = updated[i]
			}
			iterations++
		}
		result0 := matrix[0]
		result1 := last_eigenvalue
		if !result0.is_finite() || !result1.is_finite() { return -1 }
		staged := [2]f64{result0, result1}
		if output == nil || capacity < 2 { return -2 }
		output[0] = staged[0]
		output[1] = staged[1]
		return 2
	}
}
