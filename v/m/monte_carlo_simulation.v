import math

const max_simulations = 32
const max_parseable_input_length = 520

fn allowed_maturity(value f64) bool {
	return value == 0.25 || value == 0.5 || value == 1.0 || value == 2.0
}

fn allowed_step_count(value f64) bool {
	return value == 1.0 || value == 2.0 || value == 4.0 || value == 8.0 || value == 16.0
}

fn finite_value(value f64) bool {
	return !value.is_nan() && !value.is_inf()
}

@[export: 'monte_carlo_simulation']
pub fn monte_carlo_simulation(input &f64, input_length usize, mut output &f64, output_capacity usize) i64 {
	unsafe {
		if input == nil || input_length < 7 || input_length > max_parseable_input_length { return -1 }
		for index in 0 .. input_length {
			if !finite_value(input[index]) { return -1 }
		}

		s0, strike, rate := input[0], input[1], input[2]
		volatility, maturity := input[3], input[4]
		step_value, simulation_value := input[5], input[6]
		if s0 < 1.0 || s0 > 1000.0 || strike < 0.0 || strike > 2000.0 ||
			rate < -0.25 || rate > 0.25 || volatility < 0.0 || volatility > 0.5 ||
			!allowed_maturity(maturity) || !allowed_step_count(step_value) ||
			simulation_value < 1.0 || simulation_value > max_simulations ||
			f64(i64(simulation_value)) != simulation_value { return -1 }

		steps := int(step_value)
		simulations := int(simulation_value)
		if input_length != usize(7 + steps * simulations) { return -1 }
		for index in 7 .. input_length {
			if input[index] < -3.0 || input[index] > 3.0 { return -1 }
		}

		dt := maturity / f64(steps)
		sqrt_dt := math.sqrt(dt)
		drift_rate := rate - 0.5 * (volatility * volatility)
		drift := drift_rate * maturity
		mut payoffs := [max_simulations]f64{}
		for simulation in 0 .. simulations {
			mut brownian := 0.0
			offset := 7 + simulation * steps
			for step in 0 .. steps {
				brownian += sqrt_dt * input[offset + step]
			}
			exponent := drift + volatility * brownian
			terminal_price := s0 * math.exp(exponent)
			difference := terminal_price - strike
			payoffs[simulation] = if difference > 0.0 { difference } else { 0.0 }
		}

		mut total := 0.0
		for simulation in 0 .. simulations {
			total += payoffs[simulation]
		}
		option_price := (total / f64(simulations)) * math.exp(-rate * maturity)
		if !finite_value(option_price) { return -1 }
		if output == nil || output_capacity < 1 { return -2 }
		output[0] = option_price
		return 1
	}
}
