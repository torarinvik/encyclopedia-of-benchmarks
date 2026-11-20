const MAX_N: usize = 6;
const MAX_INPUT: usize = 15;
const GRID_DENOMINATOR: f64 = 18_014_398_509_481_984.0;
const MIN_NODE_SEPARATION: f64 = 0.0625;
const LOW_MAGNITUDE: f64 = 0.031_250_000_232_830_643;
const MAGNITUDE_CAP: f64 = 63.999_999_999_767_169;

fn grid_value(value: f64) -> bool {
    value.is_finite() && value >= -8.0 && value <= 8.0
        && (value * GRID_DENOMINATOR).trunc() == value * GRID_DENOMINATOR
}

fn guarded_magnitude(value: f64) -> bool {
    (value > LOW_MAGNITUDE && value < MAGNITUDE_CAP)
        || (value < -LOW_MAGNITUDE && value > -MAGNITUDE_CAP)
}

fn below_cap(value: f64) -> bool {
    value.is_finite() && value > -MAGNITUDE_CAP && value < MAGNITUDE_CAP
}

#[no_mangle]
pub unsafe extern "C" fn thiele_rational_interpolation(
    input: *const f64,
    input_length: usize,
    output: *mut f64,
    output_capacity: usize,
) -> i64 {
    if input.is_null() || !(4..=MAX_INPUT).contains(&input_length) { return -1; }
    let values = std::slice::from_raw_parts(input, input_length);
    let n_value = values[0];
    if !grid_value(n_value) || n_value.fract() != 0.0 || !(1.0..=6.0).contains(&n_value) { return -1; }
    let n = n_value as usize;
    if input_length != 2 + 2 * n { return -1; }

    let mut x = [0.0; MAX_N];
    let mut y = [0.0; MAX_N];
    let mut difference = [0.0; MAX_N * MAX_N];
    for i in 0..n {
        x[i] = values[1 + 2 * i];
        y[i] = values[2 + 2 * i];
        if !grid_value(x[i]) || !grid_value(y[i]) || x[..i].iter().any(|&previous| {
            let gap = x[i] - previous;
            gap.abs() < MIN_NODE_SEPARATION
        }) { return -1; }
        difference[i] = y[i];
    }
    let query = values[input_length - 1];
    if !grid_value(query) { return -1; }

    for order in 1..n {
        for endpoint in order..n {
            let denominator = difference[(order - 1) * MAX_N + order - 1]
                - difference[(order - 1) * MAX_N + endpoint];
            if !denominator.is_finite() || !guarded_magnitude(denominator) { return -1; }
            let value = (x[order - 1] - x[endpoint]) / denominator;
            if !below_cap(value) { return -1; }
            difference[order * MAX_N + endpoint] = value;
        }
        if !guarded_magnitude(difference[order * MAX_N + order]) { return -1; }
    }

    let mut interpolated = 0.0;
    let mut at_node = false;
    for i in 0..n {
        if query == x[i] {
            interpolated = y[i];
            at_node = true;
            break;
        }
    }
    if !at_node && n == 1 { interpolated = y[0]; }
    if !at_node && n > 1 {
        let mut tail = difference[(n - 1) * MAX_N + n - 1];
        let mut order = n - 2;
        while order > 0 {
            if !guarded_magnitude(tail) { return -1; }
            tail = difference[order * MAX_N + order] + (query - x[order]) / tail;
            if !below_cap(tail) { return -1; }
            order -= 1;
        }
        if !guarded_magnitude(tail) { return -1; }
        interpolated = y[0] + (query - x[0]) / tail;
    }
    if !below_cap(interpolated) { return -1; }
    if output.is_null() || output_capacity < 1 { return -2; }
    *output = interpolated;
    1
}
