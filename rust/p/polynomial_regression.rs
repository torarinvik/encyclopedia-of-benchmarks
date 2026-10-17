const MAX_INPUT_LENGTH: usize = 18;

fn is_finite(value: f64) -> bool { value.is_finite() }

fn exact_integer(value: f64, minimum: i64, maximum: i64) -> Option<i64> {
    if !value.is_finite() || value < minimum as f64 || value > maximum as f64 || value.trunc() != value {
        return None;
    }
    Some(value as i64)
}

#[no_mangle]
pub unsafe extern "C" fn polynomial_regression(
    input: *const f64,
    input_length: usize,
    output: *mut f64,
    capacity: usize,
) -> i64 {
    if input.is_null() || input_length < 3 || input_length > MAX_INPUT_LENGTH { return -1; }
    let (degree_value, training_value, query_value) = unsafe { (*input, *input.add(1), *input.add(2)) };
    let degree = match exact_integer(degree_value, 0, 3) { Some(value) => value as usize, None => return -1 };
    let training_count = match exact_integer(training_value, 1, 5) { Some(value) => value as usize, None => return -1 };
    let query_count = match exact_integer(query_value, 1, 4) { Some(value) => value as usize, None => return -1 };
    let columns = degree + 1;
    if training_count < columns || input_length != 3 + 2 * training_count + query_count { return -1; }

    let mut x_train = [0.0_f64; 5];
    let mut y_train = [0.0_f64; 5];
    let mut x_query = [0.0_f64; 4];
    for index in 0..training_count {
        let x = unsafe { *input.add(3 + index) };
        let y = unsafe { *input.add(3 + training_count + index) };
        if exact_integer(x, -2, 2).is_none() || exact_integer(y, -32, 32).is_none() { return -1; }
        x_train[index] = x;
        y_train[index] = y;
    }
    for index in 0..query_count {
        let x = unsafe { *input.add(3 + 2 * training_count + index) };
        if exact_integer(x, -2, 2).is_none() { return -1; }
        x_query[index] = x;
    }
    for first in 0..training_count {
        for second in first + 1..training_count {
            if x_train[first] == x_train[second] { return -1; }
        }
    }

    let mut design = [[0.0_f64; 4]; 5];
    for row in 0..training_count {
        let mut power = 1.0;
        for column in 0..columns {
            design[row][column] = power;
            power *= x_train[row];
        }
    }
    let mut q_matrix = [[0.0_f64; 4]; 5];
    let mut r_matrix = [[0.0_f64; 4]; 4];
    for column in 0..columns {
        let mut vector = [0.0_f64; 5];
        for row in 0..training_count { vector[row] = design[row][column]; }
        for previous in 0..column {
            let mut dot = 0.0;
            for row in 0..training_count { dot += q_matrix[row][previous] * design[row][column]; }
            r_matrix[previous][column] = dot;
            for row in 0..training_count { vector[row] -= dot * q_matrix[row][previous]; }
        }
        let mut norm_squared = 0.0;
        for row in 0..training_count { norm_squared += vector[row] * vector[row]; }
        if !is_finite(norm_squared) || norm_squared <= 0.0 { return -1; }
        let norm = norm_squared.sqrt();
        if !is_finite(norm) || norm <= 0.0 { return -1; }
        r_matrix[column][column] = norm;
        for row in 0..training_count { q_matrix[row][column] = vector[row] / norm; }
    }

    let mut projected = [0.0_f64; 4];
    for column in 0..columns {
        for row in 0..training_count { projected[column] += q_matrix[row][column] * y_train[row]; }
    }
    let mut coefficients = [0.0_f64; 4];
    for reverse in 0..columns {
        let column = columns - reverse - 1;
        let mut value = projected[column];
        for next in column + 1..columns { value -= r_matrix[column][next] * coefficients[next]; }
        let diagonal = r_matrix[column][column];
        if !is_finite(diagonal) || diagonal == 0.0 { return -1; }
        coefficients[column] = value / diagonal;
        if !is_finite(coefficients[column]) { return -1; }
    }

    let output_length = columns + query_count;
    let mut staged = [0.0_f64; 8];
    for column in 0..columns { staged[column] = coefficients[column]; }
    for query in 0..query_count {
        let mut prediction = 0.0;
        let mut power = 1.0;
        for column in 0..columns {
            prediction += power * coefficients[column];
            power *= x_query[query];
        }
        if !is_finite(prediction) { return -1; }
        staged[columns + query] = prediction;
    }
    if output.is_null() || capacity < output_length { return -2; }
    for index in 0..output_length { unsafe { *output.add(index) = staged[index]; } }
    output_length as i64
}
