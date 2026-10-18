const MAX_N: usize = 16;
const MAX_D: usize = 4;
const MAX_PARSEABLE_INPUT_LENGTH: usize = 84;
const PIVOT_FLOOR: f64 = 3.814697265625e-6;

fn exact_integer(value: f64, minimum: i64, maximum: i64) -> Option<usize> {
    if !value.is_finite() || value.trunc() != value || value < minimum as f64 || value > maximum as f64 {
        return None;
    }
    Some(value as usize)
}

fn grid_value(value: f64, minimum: f64, maximum: f64) -> bool {
    if !value.is_finite() || value < minimum || value > maximum { return false; }
    let scaled = value * 16.0;
    scaled.is_finite() && scaled.trunc() == scaled
}

fn solve_partial_pivot(
    mut matrix: [[f64; MAX_D]; MAX_D],
    mut rhs: [f64; MAX_D],
    dimension: usize,
) -> Option<[f64; MAX_D]> {
    let mut scale = 0.0f64;
    for index in 0..dimension {
        let diagonal = matrix[index][index].abs();
        if !diagonal.is_finite() { return None; }
        if diagonal > scale { scale = diagonal; }
    }
    if scale == 0.0 || !scale.is_finite() { return None; }

    for pivot_column in 0..dimension {
        let mut pivot_row = pivot_column;
        let mut pivot_magnitude = matrix[pivot_row][pivot_column].abs();
        for candidate in pivot_column + 1..dimension {
            let candidate_magnitude = matrix[candidate][pivot_column].abs();
            if !candidate_magnitude.is_finite() { return None; }
            if candidate_magnitude > pivot_magnitude {
                pivot_row = candidate;
                pivot_magnitude = candidate_magnitude;
            }
        }
        if !pivot_magnitude.is_finite() || pivot_magnitude <= PIVOT_FLOOR * scale { return None; }

        if pivot_row != pivot_column {
            for column in 0..dimension {
                let temporary = matrix[pivot_column][column];
                matrix[pivot_column][column] = matrix[pivot_row][column];
                matrix[pivot_row][column] = temporary;
            }
            let temporary = rhs[pivot_column];
            rhs[pivot_column] = rhs[pivot_row];
            rhs[pivot_row] = temporary;
        }

        let pivot = matrix[pivot_column][pivot_column];
        for row in pivot_column + 1..dimension {
            let factor = matrix[row][pivot_column] / pivot;
            if !factor.is_finite() { return None; }
            matrix[row][pivot_column] = 0.0;
            for column in pivot_column + 1..dimension {
                let product = factor * matrix[pivot_column][column];
                matrix[row][column] = matrix[row][column] - product;
                if !matrix[row][column].is_finite() { return None; }
            }
            let product = factor * rhs[pivot_column];
            rhs[row] = rhs[row] - product;
            if !rhs[row].is_finite() { return None; }
        }
    }

    let mut coefficients = [0.0f64; MAX_D];
    for row in (0..dimension).rev() {
        let mut residual = rhs[row];
        for column in row + 1..dimension {
            let product = matrix[row][column] * coefficients[column];
            residual = residual - product;
        }
        let diagonal = matrix[row][row];
        if !residual.is_finite() || diagonal == 0.0 || !diagonal.is_finite() { return None; }
        coefficients[row] = residual / diagonal;
        if !coefficients[row].is_finite() { return None; }
    }
    Some(coefficients)
}

#[no_mangle]
pub unsafe extern "C" fn local_weighted_learning(
    input: *const f64,
    input_length: usize,
    output: *mut f64,
    output_capacity: usize,
) -> i64 {
    if input.is_null() || input_length < 3 || input_length > MAX_PARSEABLE_INPUT_LENGTH { return -1; }
    let values = std::slice::from_raw_parts(input, input_length);
    let n = match exact_integer(values[0], 2, MAX_N as i64) { Some(value) => value, None => return -1 };
    let d = match exact_integer(values[1], 1, MAX_D as i64) { Some(value) => value, None => return -1 };
    if d > n { return -1; }
    let tau = values[2];
    if !grid_value(tau, 2.0, 8.0) { return -1; }
    if input_length != 3 + n * d + n { return -1; }

    let mut x_train = [[0.0f64; MAX_D]; MAX_N];
    let mut y_train = [0.0f64; MAX_N];
    let mut cursor = 3;
    for row in 0..n {
        for feature in 0..d {
            let value = values[cursor];
            cursor += 1;
            if !grid_value(value, -4.0, 4.0) { return -1; }
            x_train[row][feature] = value;
        }
    }
    for row in 0..n {
        let value = values[cursor];
        cursor += 1;
        if !grid_value(value, -8.0, 8.0) { return -1; }
        y_train[row] = value;
    }

    let mut staged = [0.0f64; MAX_N];
    for query in 0..n {
        let mut weights = [0.0f64; MAX_N];
        for row in 0..n {
            let mut distance_squared = 0.0f64;
            for feature in 0..d {
                let delta = x_train[query][feature] - x_train[row][feature];
                let squared_delta = delta * delta;
                distance_squared = distance_squared + squared_delta;
            }
            let tau_squared = tau * tau;
            let denominator = (-2.0) * tau_squared;
            let exponent = distance_squared / denominator;
            weights[row] = exponent.exp();
            if !weights[row].is_finite() || weights[row] <= 0.0 { return -1; }
        }

        let mut normal = [[0.0f64; MAX_D]; MAX_D];
        let mut rhs = [0.0f64; MAX_D];
        for row in 0..n {
            let mut weighted_x = [0.0f64; MAX_D];
            for feature in 0..d { weighted_x[feature] = weights[row] * x_train[row][feature]; }
            let weighted_y = weights[row] * y_train[row];
            for p in 0..d {
                let rhs_product = x_train[row][p] * weighted_y;
                rhs[p] = rhs[p] + rhs_product;
                for q in 0..d {
                    let product = x_train[row][p] * weighted_x[q];
                    normal[p][q] = normal[p][q] + product;
                }
            }
        }

        let coefficients = match solve_partial_pivot(normal, rhs, d) {
            Some(solution) => solution,
            None => return -1,
        };
        let mut prediction = 0.0f64;
        for feature in 0..d {
            let product = x_train[query][feature] * coefficients[feature];
            prediction = prediction + product;
        }
        if !prediction.is_finite() { return -1; }
        staged[query] = prediction;
    }

    if output.is_null() || output_capacity < n { return -2; }
    for index in 0..n { *output.add(index) = staged[index]; }
    n as i64
}
