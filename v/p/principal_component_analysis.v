import math

const max_samples = 8
const max_features = 4
const max_output = 34

@[export: 'principal_component_analysis']
pub fn principal_component_analysis(input &f64, input_length usize, mut output &f64, capacity usize) i64 {
	unsafe {
		if input == nil || input_length < 3 || input_length > 35 { return -1 }
		for i in 0 .. 3 {
			if !input[i].is_finite() || math.floor(input[i]) != input[i] { return -1 }
		}
		if input[0] < 2 || input[0] > 8 || input[1] < 2 || input[1] > 4 { return -1 }
		samples := int(input[0])
		features := int(input[1])
		if input[2] < 1 || input[2] > f64(features) { return -1 }
		components := int(input[2])
		if input_length != usize(3 + samples * features) { return -1 }

		mut means := [max_features]f64{}
		mut centered := [max_samples * max_features]f64{}
		for row in 0 .. samples {
			for column in 0 .. features {
				value := input[3 + row * features + column]
				if !value.is_finite() || math.abs(value) > 100 { return -1 }
				means[column] += value
				if !means[column].is_finite() { return -1 }
			}
		}
		for column in 0 .. features {
			means[column] /= f64(samples)
			if !means[column].is_finite() { return -1 }
		}
		for row in 0 .. samples {
			for column in 0 .. features {
				value := input[3 + row * features + column] - means[column]
				if !value.is_finite() { return -1 }
				centered[row * features + column] = value
			}
		}

		mut matrix := [16]f64{}
		for i in 0 .. features {
			for j in i .. features {
				mut covariance := 0.0
				for row in 0 .. samples {
					covariance += centered[row * features + i] * centered[row * features + j]
					if !covariance.is_finite() { return -1 }
				}
				covariance /= f64(samples)
				if !covariance.is_finite() { return -1 }
				matrix[i * features + j] = covariance
				matrix[j * features + i] = covariance
			}
		}
		mut deflated := matrix
		mut eigenvectors := [16]f64{}
		for component in 0 .. components {
			mut vector := [max_features]f64{}
			for i in 0 .. features { vector[i] = 1 }
			mut converged := false
			for _ in 0 .. 1000 {
				previous := vector
				mut next := [max_features]f64{}
				for i in 0 .. features {
					for j in 0 .. features {
						next[i] += deflated[i * features + j] * vector[j]
						if !next[i].is_finite() { return -1 }
					}
				}
				mut norm_squared := 0.0
				for i in 0 .. features {
					norm_squared += next[i] * next[i]
					if !norm_squared.is_finite() { return -1 }
				}
				norm := math.sqrt(norm_squared)
				if !norm.is_finite() || norm <= 1e-10 { return -1 }
				for i in 0 .. features {
					next[i] /= norm
					if !next[i].is_finite() { return -1 }
				}
				mut difference := 0.0
				for i in 0 .. features {
					change := math.abs(next[i] - previous[i])
					if !change.is_finite() { return -1 }
					if change > difference { difference = change }
				}
				vector = next
				if difference < 1e-10 {
					converged = true
					break
				}
			}
			if !converged { return -1 }
			mut numerator := 0.0
			for i in 0 .. features {
				mut row_sum := 0.0
				for j in 0 .. features {
					row_sum += deflated[i * features + j] * vector[j]
					if !row_sum.is_finite() { return -1 }
				}
				numerator += row_sum * vector[i]
				if !numerator.is_finite() { return -1 }
			}
			mut denominator := 0.0
			for i in 0 .. features {
				denominator += vector[i] * vector[i]
				if !denominator.is_finite() { return -1 }
			}
			if denominator == 0 { return -1 }
			eigenvalue := numerator / denominator
			if !eigenvalue.is_finite() { return -1 }
			for i in 0 .. features { eigenvectors[component * max_features + i] = vector[i] }
			for i in 0 .. features {
				for j in 0 .. features {
					deflated[i * features + j] -= eigenvalue * vector[i] * vector[j]
					if !deflated[i * features + j].is_finite() { return -1 }
				}
			}
		}

		mut staged := [max_output]f64{}
		staged[0] = f64(samples)
		staged[1] = f64(components)
		for row in 0 .. samples {
			for component in 0 .. components {
				mut score := 0.0
				for column in 0 .. features {
					score += eigenvectors[component * max_features + column] * centered[row * features + column]
					if !score.is_finite() { return -1 }
				}
				staged[2 + row * components + component] = score
			}
		}
		output_size := 2 + samples * components
		if output == nil || capacity < usize(output_size) { return -2 }
		for i in 0 .. output_size { output[i] = staged[i] }
		return i64(output_size)
	}
}
