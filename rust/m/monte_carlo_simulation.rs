const MAX_PARSEABLE_INPUT_LENGTH: usize = 520;
const MAX_SIMULATIONS: usize = 32;

fn allowed_maturity(value: f64) -> bool {
    value == 0.25 || value == 0.5 || value == 1.0 || value == 2.0
}

fn allowed_step_count(value: f64) -> bool {
    value == 1.0 || value == 2.0 || value == 4.0 || value == 8.0 || value == 16.0
}

#[no_mangle]
pub unsafe extern "C" fn monte_carlo_simulation(
    input: *const f64,
    input_length: usize,
    output: *mut f64,
    output_capacity: usize,
) -> i64 {
    if input.is_null() || input_length < 7 || input_length > MAX_PARSEABLE_INPUT_LENGTH {
        return -1;
    }
    let values = std::slice::from_raw_parts(input, input_length);
    if values.iter().any(|value| !value.is_finite()) {
        return -1;
    }

    let s0 = values[0];
    let strike = values[1];
    let rate = values[2];
    let volatility = values[3];
    let maturity = values[4];
    let step_value = values[5];
    let simulation_value = values[6];
    if !(1.0..=1000.0).contains(&s0)
        || !(0.0..=2000.0).contains(&strike)
        || !(-0.25..=0.25).contains(&rate)
        || !(0.0..=0.5).contains(&volatility)
        || !allowed_maturity(maturity)
        || !allowed_step_count(step_value)
        || simulation_value < 1.0
        || simulation_value > MAX_SIMULATIONS as f64
        || simulation_value.trunc() != simulation_value
    {
        return -1;
    }

    let steps = step_value as usize;
    let simulations = simulation_value as usize;
    if input_length != 7 + steps * simulations {
        return -1;
    }
    if values[7..].iter().any(|normal| !(-3.0..=3.0).contains(normal)) {
        return -1;
    }

    let dt = maturity / steps as f64;
    let sqrt_dt = dt.sqrt();
    let drift_rate = rate - 0.5 * (volatility * volatility);
    let drift = drift_rate * maturity;
    let mut payoffs = [0.0_f64; MAX_SIMULATIONS];
    for simulation in 0..simulations {
        let mut brownian = 0.0;
        let offset = 7 + simulation * steps;
        for step in 0..steps {
            brownian += sqrt_dt * values[offset + step];
        }
        let exponent = drift + volatility * brownian;
        let terminal_price = s0 * exponent.exp();
        let difference = terminal_price - strike;
        payoffs[simulation] = if difference > 0.0 { difference } else { 0.0 };
    }

    let mut total = 0.0;
    for payoff in payoffs.iter().take(simulations) {
        total += *payoff;
    }
    let option_price = (total / simulations as f64) * (-rate * maturity).exp();
    if !option_price.is_finite() {
        return -1;
    }
    if output.is_null() || output_capacity < 1 {
        return -2;
    }
    *output = option_price;
    1
}
