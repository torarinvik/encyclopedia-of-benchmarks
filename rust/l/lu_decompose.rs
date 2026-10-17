const MAX_INPUT_LENGTH: usize = 18;
const MAX_DIMENSION: usize = 4;

#[inline(never)]
fn rounded_multiply(left: f64, right: f64) -> f64 { left * right }
#[inline(never)]
fn rounded_add(left: f64, right: f64) -> f64 { left + right }
#[inline(never)]
fn rounded_subtract(left: f64, right: f64) -> f64 { left - right }
#[inline(never)]
fn rounded_divide(left: f64, right: f64) -> f64 { left / right }

fn exact_integer(value: f64, minimum: i64, maximum: i64) -> Option<i64> {
    if !value.is_finite() || value.trunc() != value || value < minimum as f64 || value > maximum as f64 {
        return None;
    }
    Some(value as i64)
}

#[no_mangle]
pub unsafe extern "C" fn lu_decompose(
    input: *const f64,
    input_length: usize,
    output: *mut f64,
    output_capacity: usize,
) -> i64 {
    if input.is_null() || input_length < 1 || input_length > MAX_INPUT_LENGTH { return -1; }
    let dimension_value = match exact_integer(*input, 1, MAX_DIMENSION as i64) { Some(value) => value, None => return -1 };
    let dimension = dimension_value as usize;
    if input_length != 1 + dimension * dimension { return -1; }
    let mut matrix = [0.0_f64; 16];
    for index in 0..dimension * dimension {
        let value = *input.add(index + 1);
        if exact_integer(value, -8, 8).is_none() { return -1; }
        matrix[index] = value;
    }
    let mut lower = [0.0_f64; 16];
    let mut upper = [0.0_f64; 16];
    for row in 0..dimension {
        for column in row..dimension {
            let mut sum = 0.0;
            for index in 0..row {
                let product = rounded_multiply(lower[row * dimension + index], upper[index * dimension + column]);
                sum = rounded_add(sum, product);
            }
            upper[row * dimension + column] = rounded_subtract(matrix[row * dimension + column], sum);
        }
        let pivot = upper[row * dimension + row];
        if pivot == 0.0 || !pivot.is_finite() { return -1; }
        lower[row * dimension + row] = 1.0;
        for lower_row in row + 1..dimension {
            let mut sum = 0.0;
            for index in 0..row {
                let product = rounded_multiply(lower[lower_row * dimension + index], upper[index * dimension + row]);
                sum = rounded_add(sum, product);
            }
            let numerator = rounded_subtract(matrix[lower_row * dimension + row], sum);
            let value = rounded_divide(numerator, pivot);
            if !value.is_finite() { return -1; }
            lower[lower_row * dimension + row] = value;
        }
    }
    for index in 0..dimension * dimension {
        if !upper[index].is_finite() || !lower[index].is_finite() { return -1; }
    }
    let output_length = 2 * dimension * dimension;
    if output.is_null() || output_capacity < output_length { return -2; }
    for index in 0..dimension * dimension { *output.add(index) = lower[index]; }
    for index in 0..dimension * dimension { *output.add(dimension * dimension + index) = upper[index]; }
    output_length as i64
}
