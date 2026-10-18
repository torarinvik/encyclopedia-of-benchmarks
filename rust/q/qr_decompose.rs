const MAX_INPUT_LENGTH: usize = 18;
const MAX_DIMENSION: usize = 4;

fn exact_integer(value: f64, minimum: i64, maximum: i64) -> Option<i64> {
    if !value.is_finite() || value.trunc() != value || value < minimum as f64 || value > maximum as f64 {
        return None;
    }
    Some(value as i64)
}

#[no_mangle]
pub unsafe extern "C" fn qr_decompose(
    input: *const f64,
    input_length: usize,
    output: *mut f64,
    output_capacity: usize,
) -> i64 {
    if input.is_null() || input_length < 1 || input_length > MAX_INPUT_LENGTH { return -1; }
    let values = std::slice::from_raw_parts(input, input_length);
    if exact_integer(values[0], 1, MAX_DIMENSION as i64).is_none() { return -1; }
    let dimension = values[0] as usize;
    let matrix_elements = dimension * dimension;
    if input_length != 1 + matrix_elements { return -1; }

    let mut matrix = [0.0_f64; 16];
    let mut bareiss = [0_i64; 16];
    for index in 0..matrix_elements {
        let value = values[index + 1];
        let integer = match exact_integer(value, -4, 4) { Some(value) => value, None => return -1 };
        matrix[index] = value;
        bareiss[index] = integer;
    }

    let mut sign = 1_i64;
    let mut previous_pivot = 1_i64;
    for pivot_column in 0..dimension.saturating_sub(1) {
        let mut pivot_row = pivot_column;
        while pivot_row < dimension && bareiss[pivot_row * dimension + pivot_column] == 0 { pivot_row += 1; }
        if pivot_row == dimension { return -1; }
        if pivot_row != pivot_column {
            for swap_column in 0..dimension {
                bareiss.swap(pivot_column * dimension + swap_column, pivot_row * dimension + swap_column);
            }
            sign = -sign;
        }
        let pivot_value = bareiss[pivot_column * dimension + pivot_column];
        for row in pivot_column + 1..dimension {
            for column in pivot_column + 1..dimension {
                let numerator = bareiss[row * dimension + column] * pivot_value
                    - bareiss[row * dimension + pivot_column] * bareiss[pivot_column * dimension + column];
                bareiss[row * dimension + column] = numerator / previous_pivot;
            }
            bareiss[row * dimension + pivot_column] = 0;
        }
        previous_pivot = pivot_value;
    }
    if sign * bareiss[(dimension - 1) * dimension + dimension - 1] == 0 { return -1; }

    let mut q = [0.0_f64; 16];
    let mut r = [0.0_f64; 16];
    for column in 0..dimension {
        let mut source = [0.0_f64; 4];
        let mut residual = [0.0_f64; 4];
        for row in 0..dimension {
            source[row] = matrix[row * dimension + column];
            residual[row] = source[row];
        }
        for previous in 0..column {
            let mut numerator = 0.0_f64;
            let mut denominator = 0.0_f64;
            for row in 0..dimension {
                numerator += source[row] * q[row * dimension + previous];
                denominator += q[row * dimension + previous] * q[row * dimension + previous];
            }
            if denominator == 0.0 || !denominator.is_finite() { return -1; }
            let scalar = numerator / denominator;
            for row in 0..dimension { residual[row] -= scalar * q[row * dimension + previous]; }
        }
        let mut residual_squared = 0.0_f64;
        for row in 0..dimension { residual_squared += residual[row] * residual[row]; }
        let magnitude = residual_squared.sqrt();
        if magnitude == 0.0 || !magnitude.is_finite() { return -1; }
        for row in 0..dimension { q[row * dimension + column] = residual[row] / magnitude; }
        for target_column in column..dimension {
            let mut dot = 0.0_f64;
            for row in 0..dimension { dot += q[row * dimension + column] * matrix[row * dimension + target_column]; }
            r[column * dimension + target_column] = dot;
        }
    }
    if (0..matrix_elements).any(|index| !q[index].is_finite() || !r[index].is_finite()) { return -1; }

    let output_length = 2 * matrix_elements;
    if output.is_null() || output_capacity < output_length { return -2; }
    for index in 0..matrix_elements {
        *output.add(index) = q[index];
        *output.add(matrix_elements + index) = r[index];
    }
    output_length as i64
}
