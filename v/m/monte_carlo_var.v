import math

const min_returns = 20
const max_returns = 64
const min_simulations = 20
const max_simulations = 128
const max_valid_input_length = 197
const max_parseable_input_length = 198

fn finite_value(value f64) bool {
	return !value.is_nan() && !value.is_inf()
}

@[export: 'monte_carlo_var']
pub fn monte_carlo_var(input &f64, input_length usize, mut output &f64, output_capacity usize) i64 {
	unsafe {
		if input == nil || input_length < 45 || input_length > max_parseable_input_length { return -1 }
		for index in 0 .. input_length {
			if !finite_value(input[index]) { return -1 }
		}
		portfolio, confidence, horizon := input[0], input[1], input[2]
		simulation_value, return_count_value := input[3], input[4]
		if portfolio < 100.0 || portfolio > 1000000.0 || confidence < 0.5 || confidence > 0.95 ||
			horizon < 1.0 || horizon > 10.0 || simulation_value < f64(min_simulations) ||
			simulation_value > f64(max_simulations) || return_count_value < f64(min_returns) ||
			return_count_value > f64(max_returns) { return -1 }
		simulation_count, return_count := int(simulation_value), int(return_count_value)
		if f64(simulation_count) != simulation_value || f64(return_count) != return_count_value { return -1 }
		if input_length != usize(5 + return_count + simulation_count) || input_length > max_valid_input_length { return -1 }

		mut returns := [max_returns]f64{}
		mut simulated := [max_simulations]f64{}
		mut sum := 0.0
		for index in 0 .. return_count {
			value := input[5 + index]
			if value < -0.25 || value > 0.25 { return -1 }
			returns[index] = value
			sum += value
		}
		for index in 0 .. simulation_count {
			z := input[5 + return_count + index]
			if z < -3.0 || z > 3.0 { return -1 }
			simulated[index] = z
		}
		mean := sum / f64(return_count)
		mut squared_deviation := 0.0
		for index in 0 .. return_count {
			delta := returns[index] - mean
			squared_deviation += delta * delta
		}
		volatility := math.sqrt(squared_deviation / f64(return_count - 1))
		if !finite_value(volatility) || volatility == 0.0 { return -1 }
		for index in 0 .. simulation_count {
			simulated[index] = mean + volatility * simulated[index]
		}
		for index in 1 .. simulation_count {
			value := simulated[index]
			mut position := index
			for position > 0 && simulated[position - 1] > value {
				simulated[position] = simulated[position - 1]
				position--
			}
			simulated[position] = value
		}

		tail_value := math.floor((1.0 - confidence) * f64(simulation_count))
		if tail_value < 1.0 || tail_value > f64(simulation_count) { return -1 }
		tail_count := int(tail_value)
		metric := -simulated[tail_count - 1] * portfolio * math.sqrt(horizon)
		if !finite_value(metric) { return -1 }
		if output == nil || output_capacity < 1 { return -2 }
		output[0] = metric
		return 1
	}
}
