package baum_welch_reestimation

import "core:c"
import "core:math"

BW_MAX_INPUT :: 48
BW_MAX_OUTPUT :: 36
BW_MIN_PROBABILITY :: 0.001
BW_ROW_TOLERANCE :: 1e-9

bw_exact_integer :: proc(value: f64, low, high: i64) -> bool {
	if !math.is_finite(value) || value < f64(low) || value > f64(high) || math.trunc(value) != value do return false
	return true
}

@(export)
baum_welch_reestimation :: proc "c" (input: [^]f64, input_length: c.size_t,
		output: [^]f64, output_capacity: c.size_t) -> i64 {
	if input == nil || input_length < 3 || input_length > BW_MAX_INPUT do return -1
	if !bw_exact_integer(input[0], 2, 4) || !bw_exact_integer(input[1], 2, 4) || !bw_exact_integer(input[2], 1, 8) do return -1
	states := int(input[0])
	symbols := int(input[1])
	time_count := int(input[2])
	if int(input_length) != 3 + states + states * states + states * symbols + time_count do return -1

	initial: [4]f64 = {}
	transition: [16]f64 = {}
	emission: [16]f64 = {}
	observations: [8]int = {}
	cursor := 3
	for i := 0; i < states; i += 1 do initial[i] = input[cursor + i]
	cursor += states
	for i := 0; i < states * states; i += 1 do transition[i] = input[cursor + i]
	cursor += states * states
	for i := 0; i < states * symbols; i += 1 do emission[i] = input[cursor + i]
	cursor += states * symbols
	total := f64(0.0)
	for i := 0; i < states; i += 1 {
		value := initial[i]
		if !math.is_finite(value) || value < BW_MIN_PROBABILITY || value > 1.0 do return -1
		total += value
	}
	if math.abs_f64(total - 1.0) > BW_ROW_TOLERANCE do return -1
	for state := 0; state < states; state += 1 {
		total = 0.0
		for j := 0; j < states; j += 1 {
			value := transition[state * states + j]
			if !math.is_finite(value) || value < BW_MIN_PROBABILITY || value > 1.0 do return -1
			total += value
		}
		if math.abs_f64(total - 1.0) > BW_ROW_TOLERANCE do return -1
		total = 0.0
		for symbol := 0; symbol < symbols; symbol += 1 {
			value := emission[state * symbols + symbol]
			if !math.is_finite(value) || value < BW_MIN_PROBABILITY || value > 1.0 do return -1
			total += value
		}
		if math.abs_f64(total - 1.0) > BW_ROW_TOLERANCE do return -1
	}
	for time := 0; time < time_count; time += 1 {
		value := input[cursor + time]
		if !bw_exact_integer(value, 0, i64(symbols - 1)) do return -1
		observations[time] = int(value)
	}

	alpha: [32]f64 = {}
	beta: [32]f64 = {}
	gamma: [32]f64 = {}
	staged: [BW_MAX_OUTPUT]f64 = {}
	for state := 0; state < states; state += 1 do alpha[state] = initial[state] * emission[state * symbols + observations[0]]
	for time := 1; time < time_count; time += 1 {
		for destination := 0; destination < states; destination += 1 {
			incoming := f64(0.0)
			for source := 0; source < states; source += 1 do incoming += alpha[(time - 1) * states + source] * transition[source * states + destination]
			alpha[time * states + destination] = incoming * emission[destination * symbols + observations[time]]
		}
	}
	likelihood := f64(0.0)
	for state := 0; state < states; state += 1 do likelihood += alpha[(time_count - 1) * states + state]
	for state := 0; state < states; state += 1 do beta[(time_count - 1) * states + state] = 1.0
	time := time_count
	for time > 1 {
		time -= 1
		for source := 0; source < states; source += 1 {
			sum := f64(0.0)
			for destination := 0; destination < states; destination += 1 {
				sum += transition[source * states + destination] * emission[destination * symbols + observations[time]] * beta[time * states + destination]
			}
			beta[(time - 1) * states + source] = sum
		}
	}
	for t := 0; t < time_count; t += 1 {
		for state := 0; state < states; state += 1 do gamma[t * states + state] = alpha[t * states + state] * beta[t * states + state] / likelihood
	}

	output_count := states + states * states + states * symbols
	out := 0
	for state := 0; state < states; state += 1 { staged[out] = gamma[state]; out += 1 }
	if time_count == 1 {
		for i := 0; i < states * states; i += 1 { staged[out] = transition[i]; out += 1 }
	} else {
		for source := 0; source < states; source += 1 {
			denominator := f64(0.0)
			for t := 0; t < time_count - 1; t += 1 do denominator += gamma[t * states + source]
			for destination := 0; destination < states; destination += 1 {
				count := f64(0.0)
				for t := 0; t < time_count - 1; t += 1 {
					count += alpha[t * states + source] * transition[source * states + destination] * emission[destination * symbols + observations[t + 1]] * beta[(t + 1) * states + destination] / likelihood
				}
				staged[out] = count / denominator
				out += 1
			}
		}
	}
	for state := 0; state < states; state += 1 {
		denominator := f64(0.0)
		for t := 0; t < time_count; t += 1 do denominator += gamma[t * states + state]
		for symbol := 0; symbol < symbols; symbol += 1 {
			count := f64(0.0)
			for t := 0; t < time_count; t += 1 { if observations[t] == symbol do count += gamma[t * states + state] }
			staged[out] = count / denominator
			out += 1
		}
	}
	if out != output_count do return -1
	if output == nil || output_capacity < c.size_t(output_count) do return -2
	for i := 0; i < output_count; i += 1 do output[i] = staged[i]
	return i64(output_count)
}
