const MIN_RETURNS: usize = 20;
const MAX_RETURNS: usize = 64;
const MIN_SIMULATIONS: usize = 20;
const MAX_SIMULATIONS: usize = 128;

unsafe fn monte_carlo_risk_impl(
    input: *const f64,
    input_length: usize,
    output: *mut f64,
    output_capacity: usize,
    expected_shortfall: bool,
) -> i64 {
    if input.is_null() || input_length < 45 || input_length > 198 { return -1; }
    let values = std::slice::from_raw_parts(input, input_length);
    if values.iter().any(|value| !value.is_finite()) { return -1; }

    let portfolio = values[0];
    let confidence = values[1];
    let horizon = values[2];
    let simulation_value = values[3];
    let return_count_value = values[4];
    if !(100.0..=1_000_000.0).contains(&portfolio)
        || !(0.5..=0.95).contains(&confidence)
        || !(1.0..=10.0).contains(&horizon)
        || simulation_value < MIN_SIMULATIONS as f64
        || simulation_value > MAX_SIMULATIONS as f64
        || return_count_value < MIN_RETURNS as f64
        || return_count_value > MAX_RETURNS as f64
        || simulation_value.trunc() != simulation_value
        || return_count_value.trunc() != return_count_value
    { return -1; }

    let simulation_count = simulation_value as usize;
    let return_count = return_count_value as usize;
    if input_length != 5 + return_count + simulation_count || input_length > 197 { return -1; }

    let mut returns = [0.0_f64; MAX_RETURNS];
    let mut simulated = [0.0_f64; MAX_SIMULATIONS];
    let mut sum = 0.0;
    for index in 0..return_count {
        let value = values[5 + index];
        if !(-0.25..=0.25).contains(&value) { return -1; }
        returns[index] = value;
        sum += value;
    }
    for index in 0..simulation_count {
        let z = values[5 + return_count + index];
        if !(-3.0..=3.0).contains(&z) { return -1; }
    }
    let mean = sum / return_count as f64;
    let mut squared_deviation = 0.0;
    for value in returns.iter().take(return_count) {
        let delta = *value - mean;
        squared_deviation += delta * delta;
    }
    let volatility = (squared_deviation / (return_count - 1) as f64).sqrt();
    if !volatility.is_finite() || volatility == 0.0 { return -1; }

    for index in 0..simulation_count {
        let z = values[5 + return_count + index];
        simulated[index] = mean + volatility * z;
    }
    for index in 1..simulation_count {
        let value = simulated[index];
        let mut position = index;
        while position > 0 && simulated[position - 1] > value {
            simulated[position] = simulated[position - 1];
            position -= 1;
        }
        simulated[position] = value;
    }

    let tail_value = ((1.0 - confidence) * simulation_count as f64).floor();
    if tail_value < 1.0 || tail_value > simulation_count as f64 { return -1; }
    let tail_count = tail_value as usize;
    let scale = portfolio * horizon.sqrt();
    let metric = if expected_shortfall {
        let tail_sum: f64 = simulated[..tail_count].iter().sum();
        -(tail_sum / tail_count as f64) * scale
    } else {
        -simulated[tail_count - 1] * scale
    };
    if !metric.is_finite() { return -1; }
    if output.is_null() || output_capacity < 1 { return -2; }
    *output = metric;
    1
}

#[no_mangle]
pub unsafe extern "C" fn monte_carlo_var(
    input: *const f64, input_length: usize, output: *mut f64, output_capacity: usize,
) -> i64 {
    monte_carlo_risk_impl(input, input_length, output, output_capacity, false)
}
