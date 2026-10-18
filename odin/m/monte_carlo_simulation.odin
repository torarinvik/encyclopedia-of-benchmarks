package monte_carlo_simulation

import "core:c"
import "core:math"

MAX_SIMULATIONS :: 32
MAX_PARSEABLE_INPUT_LENGTH :: 520

allowed_maturity :: proc(value: f64) -> bool {
	return value == 0.25 || value == 0.5 || value == 1.0 || value == 2.0
}

allowed_step_count :: proc(value: f64) -> bool {
	return value == 1.0 || value == 2.0 || value == 4.0 || value == 8.0 || value == 16.0
}

finite_value :: proc(value: f64) -> bool {
	return !math.is_nan(value) && !math.is_inf(value)
}

@(export)
monte_carlo_simulation :: proc "c" (input: [^]f64, input_length: c.size_t,
	output: [^]f64, output_capacity: c.size_t) -> i64 {
	if input == nil || input_length < 7 || input_length > MAX_PARSEABLE_INPUT_LENGTH do return -1
	for index := 0; index < int(input_length); index += 1 {
		if !finite_value(input[index]) do return -1
	}

	s0, strike, rate := input[0], input[1], input[2]
	volatility, maturity := input[3], input[4]
	step_value, simulation_value := input[5], input[6]
	if s0 < 1.0 || s0 > 1000.0 || strike < 0.0 || strike > 2000.0 ||
		rate < -0.25 || rate > 0.25 || volatility < 0.0 || volatility > 0.5 ||
		!allowed_maturity(maturity) || !allowed_step_count(step_value) ||
		simulation_value < 1.0 || simulation_value > MAX_SIMULATIONS ||
		f64(i64(simulation_value)) != simulation_value do return -1

	steps := int(step_value)
	simulations := int(simulation_value)
	if input_length != c.size_t(7 + steps * simulations) do return -1
	for index := 7; index < int(input_length); index += 1 {
		if input[index] < -3.0 || input[index] > 3.0 do return -1
	}

	dt := maturity / f64(steps)
	sqrt_dt := math.sqrt(dt)
	drift_rate := rate - 0.5 * (volatility * volatility)
	drift := drift_rate * maturity
	payoffs: [MAX_SIMULATIONS]f64
	for simulation := 0; simulation < simulations; simulation += 1 {
		brownian := 0.0
		offset := 7 + simulation * steps
		for step := 0; step < steps; step += 1 {
			brownian += sqrt_dt * input[offset + step]
		}
		exponent := drift + volatility * brownian
		terminal_price := s0 * math.exp_f64(exponent)
		difference := terminal_price - strike
		payoffs[simulation] = if difference > 0.0 then difference else 0.0
	}

	total := 0.0
	for simulation := 0; simulation < simulations; simulation += 1 {
		total += payoffs[simulation]
	}
	option_price := (total / f64(simulations)) * math.exp_f64(-rate * maturity)
	if !finite_value(option_price) do return -1
	if output == nil || output_capacity < 1 do return -2
	output[0] = option_price
	return 1
}
