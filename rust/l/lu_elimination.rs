const MAX_INPUT_LENGTH: usize = 22;
const MAX_DIMENSION: usize = 4;

fn exact_integer(value: f64, minimum: i64, maximum: i64) -> Option<i64> {
    if !value.is_finite() || value.trunc() != value || value < minimum as f64 || value > maximum as f64 {
        return None;
    }
    Some(value as i64)
}

#[no_mangle]
pub unsafe extern "C" fn lu_elimination(
    input: *const f64,
    input_length: usize,
    output: *mut f64,
    output_capacity: usize,
) -> i64 {
    if input.is_null() || input_length < 1 || input_length > MAX_INPUT_LENGTH { return -1; }
    let values = std::slice::from_raw_parts(input, input_length);
    let dimension = match exact_integer(values[0], 0, MAX_DIMENSION as i64) {
        Some(value) => value as usize,
        None => return -1,
    };
    let matrix_elements = dimension * dimension;
    if input_length != 1 + matrix_elements + dimension { return -1; }

    let mut matrix = [0.0_f64; 16];
    let mut rhs = [0.0_f64; 4];
    for index in 0..matrix_elements {
        let value = match exact_integer(values[1 + index], -1, 1) { Some(value) => value, None => return -1 };
        matrix[index] = value as f64;
    }
    for index in 0..dimension {
        let value = match exact_integer(values[1 + matrix_elements + index], -8, 8) { Some(value) => value, None => return -1 };
        rhs[index] = value as f64;
    }

    let mut lower = [0.0_f64; 16];
    let mut upper = [0.0_f64; 16];
    for row in 0..dimension {
        for column in row..dimension {
            let mut sum = 0.0_f64;
            for index in 0..row { sum += lower[row * dimension + index] * upper[index * dimension + column]; }
            upper[row * dimension + column] = matrix[row * dimension + column] - sum;
        }
        let pivot = upper[row * dimension + row];
        if pivot == 0.0 || !pivot.is_finite() { return -1; }
        for column in row..dimension {
            if row == column {
                lower[row * dimension + row] = 1.0;
            } else {
                let mut sum = 0.0_f64;
                for index in 0..row { sum += lower[column * dimension + index] * upper[index * dimension + row]; }
                lower[column * dimension + row] = (matrix[column * dimension + row] - sum) / pivot;
                if !lower[column * dimension + row].is_finite() { return -1; }
            }
        }
    }

    let mut transformed = [0.0_f64; 4];
    for row in 0..dimension {
        let mut sum = 0.0_f64;
        for column in 0..row { sum += transformed[column] * lower[row * dimension + column]; }
        transformed[row] = (rhs[row] - sum) / lower[row * dimension + row];
        if !transformed[row].is_finite() { return -1; }
    }

    let mut solution = [0.0_f64; 4];
    for row in (0..dimension).rev() {
        let mut sum = 0.0_f64;
        for column in row..dimension { sum += solution[column] * upper[row * dimension + column]; }
        let pivot = upper[row * dimension + row];
        if pivot == 0.0 || !pivot.is_finite() { return -1; }
        solution[row] = (transformed[row] - sum) / pivot;
        if !solution[row].is_finite() { return -1; }
    }

    if output.is_null() || output_capacity < dimension { return -2; }
    for index in 0..dimension { *output.add(index) = solution[index]; }
    dimension as i64
}
