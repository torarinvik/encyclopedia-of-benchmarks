module metropolis_mcmc

import math

const max_states = 8
const max_steps = 64
const max_input = 140

fn bounded_integer(value f64, minimum f64, maximum f64) bool {
	return value.is_finite() && math.trunc(value) == value && value >= minimum && value <= maximum
}

@[export: 'metropolis_mcmc']
pub fn metropolis_mcmc(input &f64, length usize, mut output &f64, capacity usize) i64 {
	unsafe {
		if input == nil || length < 4 || length > usize(max_input) { return -1 }
		if !bounded_integer(input[0], 1.0, f64(max_states)) ||
			!bounded_integer(input[1], 0.0, f64(max_steps)) { return -1 }
		states := int(input[0])
		steps := int(input[1])
		if !bounded_integer(input[2], 0.0, f64(states - 1)) ||
			!input[3].is_finite() || input[3] < 0.001 || input[3] > 1000.0 ||
			length != usize(4 + states + 2 * steps) { return -1 }
		for state in 0 .. states {
			energy := input[4 + state]
			if !energy.is_finite() || energy < -1_000_000.0 || energy > 1_000_000.0 { return -1 }
		}
		proposal_start := 4 + states
		uniform_start := proposal_start + steps
		for step in 0 .. steps {
			if !bounded_integer(input[proposal_start + step], 0.0, f64(states - 1)) { return -1 }
			uniform := input[uniform_start + step]
			if !uniform.is_finite() || uniform < 0.0 || uniform >= 1.0 { return -1 }
		}
		if output == nil || capacity < usize(steps + 1) { return -2 }

		mut current := int(input[2])
		output[0] = f64(current)
		for step in 0 .. steps {
			proposal := int(input[proposal_start + step])
			delta := (input[4 + proposal] - input[4 + current]) / input[3]
			if delta <= 0.0 { current = proposal }
			else if input[uniform_start + step] < math.exp(-delta) { current = proposal }
			output[step + 1] = f64(current)
		}
		return i64(steps + 1)
	}
}
