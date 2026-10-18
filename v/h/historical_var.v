module historical_var

import math

@[export: 'historical_var']
pub fn historical_var(input &f64, input_length usize, mut output &f64, capacity usize) i64 {
	unsafe {
		if isnil(input) || input_length < 24 || input_length > 69 { return -1 }
		for i in 0 .. input_length { if !input[i].is_finite() { return -1 } }
		portfolio_value := input[0]
		confidence_level := input[1]
		time_horizon := input[2]
		count_value := input[3]
		if count_value < 20.0 || count_value > 64.0 || math.floor(count_value) != count_value { return -1 }
		return_count := usize(count_value)
		if input_length != 4 + return_count || portfolio_value < 100.0 || portfolio_value > 1000000.0 ||
			confidence_level < 0.5 || confidence_level > 0.95 || time_horizon < 1.0 || time_horizon > 10.0 { return -1 }
		mut sorted_returns := [64]f64{}
		for i in 0 .. return_count {
			value := input[4 + i]
			if value < -0.25 || value > 0.25 { return -1 }
			mut position := i
			for position > 0 && sorted_returns[position - 1] > value {
				sorted_returns[position] = sorted_returns[position - 1]
				position--
			}
			sorted_returns[position] = value
		}
		index := int(math.floor((1.0 - confidence_level) * f64(return_count)))
		if index < 1 { return -1 }
		result := -sorted_returns[index - 1] * portfolio_value * math.sqrt(time_horizon)
		if isnil(output) || capacity < 1 { return -2 }
		output[0] = result
		return 1
	}
}
