/// Perform one bounded Baum–Welch update for a discrete HMM.
const MAX_INPUT: usize = 48;
const MAX_OUTPUT: usize = 36;
const MIN_PROBABILITY: f64 = 0.001;
const ROW_TOLERANCE: f64 = 1e-9;

fn exact_integer(value: f64, low: i64, high: i64) -> Option<usize> {
    if !value.is_finite() || value < low as f64 || value > high as f64 || value.fract() != 0.0 {
        return None;
    }
    Some(value as usize)
}

fn valid_row(row: &[f64]) -> bool {
    row.iter().all(|&value| value.is_finite() && (MIN_PROBABILITY..=1.0).contains(&value))
        && (row.iter().sum::<f64>() - 1.0).abs() <= ROW_TOLERANCE
}

#[no_mangle]
pub unsafe extern "C" fn baum_welch_reestimation(input: *const f64, input_length: usize,
        output: *mut f64, output_capacity: usize) -> i64 {
    if input.is_null() || input_length < 3 || input_length > MAX_INPUT { return -1; }
    let values = std::slice::from_raw_parts(input, input_length);
    let Some(states) = exact_integer(values[0], 2, 4) else { return -1; };
    let Some(symbols) = exact_integer(values[1], 2, 4) else { return -1; };
    let Some(time_count) = exact_integer(values[2], 1, 8) else { return -1; };
    if input_length != 3 + states + states * states + states * symbols + time_count { return -1; }

    let mut cursor = 3;
    let mut initial = [0.0; 4];
    let mut transition = [0.0; 16];
    let mut emission = [0.0; 16];
    let mut observations = [0usize; 8];
    initial[..states].copy_from_slice(&values[cursor..cursor + states]);
    cursor += states;
    transition[..states * states].copy_from_slice(&values[cursor..cursor + states * states]);
    cursor += states * states;
    emission[..states * symbols].copy_from_slice(&values[cursor..cursor + states * symbols]);
    cursor += states * symbols;
    if !valid_row(&initial[..states]) { return -1; }
    for state in 0..states {
        if !valid_row(&transition[state * states..(state + 1) * states])
            || !valid_row(&emission[state * symbols..(state + 1) * symbols]) { return -1; }
    }
    for time in 0..time_count {
        let Some(observation) = exact_integer(values[cursor + time], 0, symbols as i64 - 1) else { return -1; };
        observations[time] = observation;
    }

    let mut alpha = [0.0; 32];
    let mut beta = [0.0; 32];
    let mut gamma = [0.0; 32];
    let mut staged = [0.0; MAX_OUTPUT];
    for state in 0..states { alpha[state] = initial[state] * emission[state * symbols + observations[0]]; }
    for time in 1..time_count {
        for destination in 0..states {
            let mut incoming = 0.0;
            for source in 0..states { incoming += alpha[(time - 1) * states + source] * transition[source * states + destination]; }
            alpha[time * states + destination] = incoming * emission[destination * symbols + observations[time]];
        }
    }
    let likelihood: f64 = alpha[(time_count - 1) * states..time_count * states].iter().sum();
    for state in 0..states { beta[(time_count - 1) * states + state] = 1.0; }
    for time in (0..time_count.saturating_sub(1)).rev() {
        for source in 0..states {
            let mut total = 0.0;
            for destination in 0..states {
                total += transition[source * states + destination]
                    * emission[destination * symbols + observations[time + 1]]
                    * beta[(time + 1) * states + destination];
            }
            beta[time * states + source] = total;
        }
    }
    for time in 0..time_count {
        for state in 0..states {
            gamma[time * states + state] = alpha[time * states + state] * beta[time * states + state] / likelihood;
        }
    }

    let output_count = states + states * states + states * symbols;
    let mut out = 0;
    for state in 0..states { staged[out] = gamma[state]; out += 1; }
    if time_count == 1 {
        staged[out..out + states * states].copy_from_slice(&transition[..states * states]);
        out += states * states;
    } else {
        for source in 0..states {
            let denominator: f64 = (0..time_count - 1).map(|time| gamma[time * states + source]).sum();
            for destination in 0..states {
                let mut count = 0.0;
                for time in 0..time_count - 1 {
                    count += alpha[time * states + source] * transition[source * states + destination]
                        * emission[destination * symbols + observations[time + 1]]
                        * beta[(time + 1) * states + destination] / likelihood;
                }
                staged[out] = count / denominator;
                out += 1;
            }
        }
    }
    for state in 0..states {
        let denominator: f64 = (0..time_count).map(|time| gamma[time * states + state]).sum();
        for symbol in 0..symbols {
            let mut count = 0.0;
            for time in 0..time_count {
                if observations[time] == symbol { count += gamma[time * states + state]; }
            }
            staged[out] = count / denominator;
            out += 1;
        }
    }
    if out != output_count { return -1; }
    if output.is_null() || output_capacity < output_count { return -2; }
    let destination = std::slice::from_raw_parts_mut(output, output_count);
    destination.copy_from_slice(&staged[..output_count]);
    output_count as i64
}
