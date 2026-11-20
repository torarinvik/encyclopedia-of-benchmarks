module baum_welch_reestimation

import math

fn bw_exact_integer(value f64, low i64, high i64) bool {
	return value.is_finite() && value >= f64(low) && value <= f64(high) && f64(i64(value)) == value
}

@[export: 'baum_welch_reestimation']
pub fn baum_welch_reestimation(input &f64, input_length usize, mut output &f64, output_capacity usize) i64 {
	unsafe {
		if input == nil || input_length < 3 || input_length > 48 { return -1 }
		if !bw_exact_integer(input[0], 2, 4) || !bw_exact_integer(input[1], 2, 4) || !bw_exact_integer(input[2], 1, 8) { return -1 }
		states := int(input[0])
		symbols := int(input[1])
		time_count := int(input[2])
		if input_length != usize(3 + states + states * states + states * symbols + time_count) { return -1 }
		mut initial := [4]f64{}
		mut transition := [16]f64{}
		mut emission := [16]f64{}
		mut observations := [8]int{}
		mut cursor := 3
		for i in 0 .. states { initial[i] = input[cursor + i] }
		cursor += states
		for i in 0 .. states * states { transition[i] = input[cursor + i] }
		cursor += states * states
		for i in 0 .. states * symbols { emission[i] = input[cursor + i] }
		cursor += states * symbols
		mut total := f64(0.0)
		for i in 0 .. states {
			value := initial[i]
			if !value.is_finite() || value < 0.001 || value > 1.0 { return -1 }
			total += value
		}
		if math.abs(total - 1.0) > 1e-9 { return -1 }
		for state in 0 .. states {
			total = 0.0
			for j in 0 .. states {
				value := transition[state * states + j]
				if !value.is_finite() || value < 0.001 || value > 1.0 { return -1 }
				total += value
			}
			if math.abs(total - 1.0) > 1e-9 { return -1 }
			total = 0.0
			for symbol in 0 .. symbols {
				value := emission[state * symbols + symbol]
				if !value.is_finite() || value < 0.001 || value > 1.0 { return -1 }
				total += value
			}
			if math.abs(total - 1.0) > 1e-9 { return -1 }
		}
		for time in 0 .. time_count {
			if !bw_exact_integer(input[cursor + time], 0, i64(symbols - 1)) { return -1 }
			observations[time] = int(input[cursor + time])
		}

		mut alpha := [32]f64{}
		mut beta := [32]f64{}
		mut gamma := [32]f64{}
		mut staged := [36]f64{}
		for state in 0 .. states { alpha[state] = initial[state] * emission[state * symbols + observations[0]] }
		for time in 1 .. time_count {
			for destination in 0 .. states {
				mut incoming := f64(0.0)
				for source in 0 .. states { incoming += alpha[(time - 1) * states + source] * transition[source * states + destination] }
				alpha[time * states + destination] = incoming * emission[destination * symbols + observations[time]]
			}
		}
		mut likelihood := f64(0.0)
		for state in 0 .. states { likelihood += alpha[(time_count - 1) * states + state] }
		for state in 0 .. states { beta[(time_count - 1) * states + state] = 1.0 }
		mut time := time_count
		for time > 1 {
			time--
			for source in 0 .. states {
				mut sum := f64(0.0)
				for destination in 0 .. states { sum += transition[source * states + destination] * emission[destination * symbols + observations[time]] * beta[time * states + destination] }
				beta[(time - 1) * states + source] = sum
			}
		}
		for t in 0 .. time_count {
			for state in 0 .. states { gamma[t * states + state] = alpha[t * states + state] * beta[t * states + state] / likelihood }
		}

		output_count := states + states * states + states * symbols
		mut out := 0
		for state in 0 .. states { staged[out] = gamma[state]; out++ }
		if time_count == 1 {
			for i in 0 .. states * states { staged[out] = transition[i]; out++ }
		} else {
			for source in 0 .. states {
				mut denominator := f64(0.0)
				for t in 0 .. time_count - 1 { denominator += gamma[t * states + source] }
				for destination in 0 .. states {
					mut count := f64(0.0)
					for t in 0 .. time_count - 1 { count += alpha[t * states + source] * transition[source * states + destination] * emission[destination * symbols + observations[t + 1]] * beta[(t + 1) * states + destination] / likelihood }
					staged[out] = count / denominator
					out++
				}
			}
		}
		for state in 0 .. states {
			mut denominator := f64(0.0)
			for t in 0 .. time_count { denominator += gamma[t * states + state] }
			for symbol in 0 .. symbols {
				mut count := f64(0.0)
				for t in 0 .. time_count { if observations[t] == symbol { count += gamma[t * states + state] } }
				staged[out] = count / denominator
				out++
			}
		}
		if out != output_count { return -1 }
		if output == nil || output_capacity < usize(output_count) { return -2 }
		for i in 0 .. output_count { output[i] = staged[i] }
		return i64(output_count)
	}
}
