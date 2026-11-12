const MAX_STEPS: usize = 8;
const MAX_FACTORS: usize = 3;

fn in_range(value: f64, minimum: f64, maximum: f64) -> bool {
    value.is_finite() && value >= minimum && value <= maximum
}

#[no_mangle]
pub unsafe extern "C" fn hjm_forward_path(
    input: *const f64,
    input_length: usize,
    output: *mut f64,
    output_capacity: usize,
) -> i64 {
    if input.is_null() || !(7..=54).contains(&input_length) {
        return -1;
    }
    let values = unsafe { std::slice::from_raw_parts(input, input_length) };
    if values.iter().any(|value| !value.is_finite()) {
        return -1;
    }
    let steps_value = values[0];
    let factors_value = values[1];
    if !in_range(steps_value, 2.0, MAX_STEPS as f64)
        || !in_range(factors_value, 1.0, MAX_FACTORS as f64)
        || steps_value.fract() != 0.0
        || factors_value.fract() != 0.0
    {
        return -1;
    }
    let steps = steps_value as usize;
    let factors = factors_value as usize;
    let years = values[2];
    if years != 1.0 && years != 2.0 && years != 3.0 {
        return -1;
    }
    let expected = 3 + steps + 2 * factors * (steps - 1);
    if input_length != expected {
        return -1;
    }

    let mut yields = [0.0; MAX_STEPS];
    let mut vols = [[0.0; MAX_STEPS - 1]; MAX_FACTORS];
    let mut shocks = [[0.0; MAX_FACTORS]; MAX_STEPS - 1];
    let mut forwards = [0.0; MAX_STEPS];
    let mut factor_drifts = [[0.0; MAX_STEPS - 1]; MAX_FACTORS];
    let mut total_drifts = [0.0; MAX_STEPS - 1];
    let mut path = [0.0; MAX_STEPS * MAX_STEPS];

    let mut cursor = 3;
    for maturity in 0..steps {
        let value = values[cursor];
        cursor += 1;
        if !in_range(value, -0.05, 0.20) {
            return -1;
        }
        yields[maturity] = value;
    }
    for factor in 0..factors {
        for maturity in 0..steps - 1 {
            let value = values[cursor];
            cursor += 1;
            if !in_range(value, 0.0, 0.30) {
                return -1;
            }
            vols[factor][maturity] = value;
        }
    }
    for time in 0..steps - 1 {
        for factor in 0..factors {
            let value = values[cursor];
            cursor += 1;
            if !in_range(value, -3.0, 3.0) {
                return -1;
            }
            shocks[time][factor] = value;
        }
    }

    let dt = years / steps as f64;
    forwards[0] = yields[0];
    for maturity in 1..steps {
        forwards[maturity] = (maturity + 1) as f64 * yields[maturity]
            - maturity as f64 * yields[maturity - 1];
    }
    for factor in 0..factors {
        factor_drifts[factor][0] = 0.5 * dt * vols[factor][0] * vols[factor][0];
        for maturity in 1..steps - 1 {
            let mut drift = 0.0;
            for prior in 0..maturity {
                drift -= factor_drifts[factor][prior];
            }
            let mut prefix_volatility = 0.0;
            for prior in 0..=maturity {
                prefix_volatility += vols[factor][prior];
            }
            drift += 0.5 * dt * prefix_volatility * prefix_volatility;
            factor_drifts[factor][maturity] = drift;
        }
    }
    for maturity in 0..steps - 1 {
        for factor in 0..factors {
            total_drifts[maturity] += factor_drifts[factor][maturity];
        }
    }
    path[..steps].copy_from_slice(&forwards[..steps]);
    let root_dt = dt.sqrt();
    for time in 1..steps {
        for maturity in 0..steps - time {
            let mut total_shock = 0.0;
            for factor in 0..factors {
                total_shock += vols[factor][maturity] * shocks[time - 1][factor];
            }
            path[time * steps + maturity] = path[(time - 1) * steps + maturity + 1]
                + total_drifts[maturity] * dt
                + root_dt * total_shock;
        }
    }

    let needed = steps * steps;
    if output.is_null() || output_capacity < needed {
        return -2;
    }
    for index in 0..needed {
        unsafe { *output.add(index) = path[index] };
    }
    needed as i64
}
