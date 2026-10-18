const MAX_INPUT_LENGTH: usize = 18;
const MAX_DIMENSION: usize = 4;

fn exact_integer(value: f64, minimum: i64, maximum: i64) -> Option<i64> {
    if !value.is_finite() || value.trunc() != value || value < minimum as f64 || value > maximum as f64 {
        return None;
    }
    Some(value as i64)
}

#[no_mangle]
pub unsafe extern "C" fn qr_decomposition(
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
    let mut exact = [0_i64; 16];
    for index in 0..matrix_elements {
        let value = values[index + 1];
        let integer = match exact_integer(value, -1, 1) { Some(value) => value, None => return -1 };
        matrix[index] = value;
        exact[index] = integer;
    }

    // Bareiss elimination without row swaps checks every leading principal minor.
    let mut previous_pivot = 1_i64;
    for pivot_column in 0..dimension {
        let pivot = exact[pivot_column * dimension + pivot_column];
        if pivot == 0 { return -1; }
        for row in pivot_column + 1..dimension {
            for column in pivot_column + 1..dimension {
                let numerator = exact[row * dimension + column] * pivot
                    - exact[row * dimension + pivot_column] * exact[pivot_column * dimension + column];
                exact[row * dimension + column] = numerator / previous_pivot;
            }
            exact[row * dimension + pivot_column] = 0;
        }
        previous_pivot = pivot;
    }

    let mut q = [0.0_f64; 16];
    let mut r = [0.0_f64; 16];
    for column in 0..dimension {
        let mut residual = [0.0_f64; 4];
        for row in 0..dimension { residual[row] = matrix[row * dimension + column]; }
        for previous in 0..column {
            let mut projection = 0.0_f64;
            for row in 0..dimension { projection += q[row * dimension + previous] * residual[row]; }
            r[previous * dimension + column] = projection;
            for row in 0..dimension { residual[row] -= projection * q[row * dimension + previous]; }
        }
        let mut squared = 0.0_f64;
        for row in 0..dimension { squared += residual[row] * residual[row]; }
        let magnitude = squared.sqrt();
        if magnitude == 0.0 || !magnitude.is_finite() { return -1; }
        r[column * dimension + column] = magnitude;
        for row in 0..dimension { q[row * dimension + column] = residual[row] / magnitude; }
    }

    let mut reconstruction_squared = 0.0_f64;
    let mut orthogonality_squared = 0.0_f64;
    let mut lower_squared = 0.0_f64;
    for row in 0..dimension {
        for column in 0..dimension {
            let mut reconstructed = 0.0_f64;
            let mut orthogonality = 0.0_f64;
            for inner in 0..dimension {
                reconstructed += q[row * dimension + inner] * r[inner * dimension + column];
                orthogonality += q[inner * dimension + row] * q[inner * dimension + column];
            }
            let reconstruction_error = matrix[row * dimension + column] - reconstructed;
            reconstruction_squared += reconstruction_error * reconstruction_error;
            if row == column { orthogonality -= 1.0; }
            orthogonality_squared += orthogonality * orthogonality;
            if row > column { lower_squared += r[row * dimension + column] * r[row * dimension + column]; }
        }
    }
    let result = [reconstruction_squared.sqrt(), orthogonality_squared.sqrt(), lower_squared.sqrt()];
    if result.iter().any(|value| !value.is_finite()) { return -1; }
    if output.is_null() || output_capacity < 3 { return -2; }
    for index in 0..3 { *output.add(index) = result[index]; }
    3
}
