const MAX_N: usize = 10;
const MAX_INPUT_LENGTH: usize = 13;
const MAX_ORDER: usize = 6;

#[no_mangle]
pub unsafe extern "C" fn wynn_epsilon_sequence_algorithm(
    input: *const f64,
    input_length: usize,
    output: *mut f64,
    output_capacity: usize,
) -> i64 {
    if input.is_null() || !(3..=MAX_INPUT_LENGTH).contains(&input_length) {
        return -1;
    }
    let values = unsafe { std::slice::from_raw_parts(input, input_length) };
    if values.iter().any(|value| !value.is_finite()) {
        return -1;
    }
    let n_value = values[0];
    let k_value = values[1];
    if n_value.fract() != 0.0 || k_value.fract() != 0.0
        || !(5.0..=MAX_N as f64).contains(&n_value)
        || !(2.0..=3.0).contains(&k_value) {
        return -1;
    }
    let n = n_value as usize;
    let k = k_value as usize;
    if n < 2 * k + 1 || input_length != n + 2 {
        return -1;
    }
    for &sample in &values[2..] {
        let scaled = sample * 256.0;
        if !(-2.0..=2.0).contains(&sample) || scaled.fract() != 0.0 {
            return -1;
        }
    }

    let mut rows = [[0.0_f64; MAX_N]; MAX_ORDER + 1];
    let mut valid = [[false; MAX_N]; MAX_ORDER + 1];
    for i in 0..n {
        rows[0][i] = values[i + 2];
        valid[0][i] = true;
    }
    for order in 0..2 * k {
        for i in 0..n - order - 1 {
            let auxiliary_valid = order == 0 || valid[order - 1][i + 1];
            if !valid[order][i] || !valid[order][i + 1] || !auxiliary_valid {
                continue;
            }
            let denominator = rows[order][i + 1] - rows[order][i];
            if denominator == 0.0 || !denominator.is_finite() {
                continue;
            }
            let reciprocal = 1.0 / denominator;
            let auxiliary = if order == 0 { 0.0 } else { rows[order - 1][i + 1] };
            let value = auxiliary + reciprocal;
            if !reciprocal.is_finite() || !value.is_finite() {
                continue;
            }
            rows[order + 1][i] = value;
            valid[order + 1][i] = true;
        }
    }

    let needed: usize = (2..=2 * k).step_by(2).map(|order| 2 * (n - order)).sum();
    if output.is_null() || output_capacity < needed {
        return -2;
    }
    let destination = unsafe { std::slice::from_raw_parts_mut(output, needed) };
    let mut cursor = 0;
    for order in (2..=2 * k).step_by(2) {
        for i in 0..n - order {
            destination[cursor] = if valid[order][i] { 0.0 } else { 1.0 };
            destination[cursor + 1] = if valid[order][i] { rows[order][i] } else { 0.0 };
            cursor += 2;
        }
    }
    needed as i64
}
