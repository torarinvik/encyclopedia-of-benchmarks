module matrix_chain_multiplication

const max_dims = 65
const max_dimension = i64(1000)

@[export: 'matrix_chain_multiplication']
pub fn matrix_chain_multiplication(dimensions &i64, length usize) i64 {
	if length > max_dims { return -1 }
	for index in 0 .. length {
		dimension := unsafe { dimensions[index] }
		if dimension < 1 || dimension > max_dimension { return -1 }
	}
	if length < 2 { return 0 }

	matrix_count := length - 1
	mut costs := [4225]i64{}
	for chain_length in 2 .. matrix_count + 1 {
		for start in 0 .. matrix_count - chain_length + 1 {
			finish := start + chain_length - 1
			mut best := i64(9223372036854775807)
			for split in start .. finish {
				cost := costs[start * max_dims + split]
					+ costs[(split + 1) * max_dims + finish]
					+ unsafe { dimensions[start] * dimensions[split + 1] * dimensions[finish + 1] }
				if cost < best { best = cost }
			}
			costs[start * max_dims + finish] = best
		}
	}
	return costs[matrix_count - 1]
}
