package metropolis_mcmc

import "core:c"
import "core:math"

MAX_STATES :: 8
MAX_STEPS :: 64
MAX_INPUT :: 140

bounded_integer :: proc "contextless" (value, minimum, maximum: f64) -> bool {
	return math.is_finite(value) && math.trunc(value) == value && value >= minimum && value <= maximum
}

@(export)
metropolis_mcmc :: proc "c" (input: [^]f64, length: c.size_t,
	output: [^]f64, capacity: c.size_t) -> i64 {
	if input == nil || length < 4 || length > MAX_INPUT do return -1
	if !bounded_integer(input[0], 1.0, f64(MAX_STATES)) ||
		!bounded_integer(input[1], 0.0, f64(MAX_STEPS)) do return -1
	states, steps := int(input[0]), int(input[1])
	if !bounded_integer(input[2], 0.0, f64(states - 1)) ||
		!math.is_finite(input[3]) || input[3] < 0.001 || input[3] > 1000.0 ||
		length != c.size_t(4 + states + 2 * steps) do return -1
	for state := 0; state < states; state += 1 {
		energy := input[4 + state]
		if !math.is_finite(energy) || energy < -1_000_000.0 || energy > 1_000_000.0 do return -1
	}
	proposal_start := 4 + states
	uniform_start := proposal_start + steps
	for step := 0; step < steps; step += 1 {
		if !bounded_integer(input[proposal_start + step], 0.0, f64(states - 1)) do return -1
		uniform := input[uniform_start + step]
		if !math.is_finite(uniform) || uniform < 0.0 || uniform >= 1.0 do return -1
	}
	if output == nil || capacity < c.size_t(steps + 1) do return -2

	current := int(input[2])
	output[0] = f64(current)
	for step := 0; step < steps; step += 1 {
		proposal := int(input[proposal_start + step])
		delta := (input[4 + proposal] - input[4 + current]) / input[3]
		if delta <= 0.0 do current = proposal
		else if input[uniform_start + step] < math.exp_f64(-delta) do current = proposal
		output[step + 1] = f64(current)
	}
	return i64(steps + 1)
}
