module adagrad

const max_steps = 256
const max_groups = 16
const input_scale = 1_000_000_000.0
const output_scale = 1_000_000.0

fn adagrad_sqrt(value f64) f64 {
	if value <= 0.0 { return 0.0 }
	mut root := if value > 1.0 { value } else { 1.0 }
	for _ in 0 .. 80 { root = 0.5 * (root + value / root) }
	return root
}

@[export: 'adagrad']
pub fn adagrad(input &i64, length usize, output &u8, output_capacity usize) i64 {
	if length < 6 || length > 3 + 3 * max_steps { return -1 }
	unsafe {
		steps_value := input[0]
		learning_rate_value := input[1]
		epsilon_value := input[2]
		if steps_value < 1 || steps_value > max_steps || length != usize(3 + 3 * steps_value) ||
			learning_rate_value < 1 || learning_rate_value > 1000000000 ||
			epsilon_value < 1 || epsilon_value > 10000000 { return -1 }
		steps := int(steps_value)
		for step in 0 .. steps {
			id := input[3 + 3 * step]
			parameter := input[4 + 3 * step]
			gradient := input[5 + 3 * step]
			if id < 0 || id >= max_groups || parameter < -1000000000000000 || parameter > 1000000000000000 ||
				gradient < -1000000000000 || gradient > 1000000000000 { return -1 }
		}
		if output_capacity < 8 * steps { return -2 }
		learning_rate := f64(learning_rate_value) / input_scale
		epsilon := f64(epsilon_value) / input_scale
		mut accumulated := [max_groups]f64{init: 0.0}
		for step in 0 .. steps {
			id := int(input[3 + 3 * step])
			parameter := f64(input[4 + 3 * step]) / input_scale
			gradient := f64(input[5 + 3 * step]) / input_scale
			accumulated[id] += gradient * gradient
			updated := parameter - learning_rate / (adagrad_sqrt(accumulated[id]) + epsilon) * gradient
			encoded := i64(updated * output_scale)
			for byte in 0 .. 8 { output[8 * step + byte] = u8((encoded >> (8 * byte)) & 255) }
		}
		return i64(steps)
	}
}
