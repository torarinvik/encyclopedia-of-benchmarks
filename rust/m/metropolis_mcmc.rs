const MAX_STATES: usize = 8;
const MAX_STEPS: usize = 64;
const MAX_INPUT: usize = 140;

fn bounded_integer(value: f64, minimum: f64, maximum: f64) -> bool {
    value.is_finite() && value.fract() == 0.0 && value >= minimum && value <= maximum
}

#[no_mangle]
pub unsafe extern "C" fn metropolis_mcmc(
    input: *const f64,
    length: usize,
    output: *mut f64,
    capacity: usize,
) -> i64 {
    if input.is_null() || length < 4 || length > MAX_INPUT { return -1; }
    if !bounded_integer(*input, 1.0, MAX_STATES as f64)
        || !bounded_integer(*input.add(1), 0.0, MAX_STEPS as f64) { return -1; }
    let states = *input as usize;
    let steps = *input.add(1) as usize;
    if !bounded_integer(*input.add(2), 0.0, (states - 1) as f64)
        || !(*input.add(3)).is_finite()
        || *input.add(3) < 0.001 || *input.add(3) > 1000.0
        || length != 4 + states + 2 * steps { return -1; }
    for state in 0..states {
        let energy = *input.add(4 + state);
        if !energy.is_finite() || energy.abs() > 1_000_000.0 { return -1; }
    }
    let proposal_start = 4 + states;
    let uniform_start = proposal_start + steps;
    for step in 0..steps {
        if !bounded_integer(*input.add(proposal_start + step), 0.0, (states - 1) as f64) {
            return -1;
        }
        let uniform = *input.add(uniform_start + step);
        if !uniform.is_finite() || uniform < 0.0 || uniform >= 1.0 { return -1; }
    }
    if output.is_null() || capacity < steps + 1 { return -2; }

    let mut current = *input.add(2) as usize;
    *output = current as f64;
    for step in 0..steps {
        let proposal = *input.add(proposal_start + step) as usize;
        let delta = (*input.add(4 + proposal) - *input.add(4 + current)) / *input.add(3);
        if delta <= 0.0 {
            current = proposal;
        } else if *input.add(uniform_start + step) < (-delta).exp() {
            current = proposal;
        }
        *output.add(step + 1) = current as f64;
    }
    (steps + 1) as i64
}
