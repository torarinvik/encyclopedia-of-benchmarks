const MAX_DIMENSION: usize = 4;
const MAX_INPUT_LENGTH: usize = 26;
const MAX_OUTPUT_ELEMENTS: usize = 16;

/// Apply the bounded Sherman–Morrison rank-one inverse update.
#[no_mangle]
pub unsafe extern "C" fn sherman_morrison(input: *const f64, input_length: usize,
                                           output: *mut f64, output_capacity: usize) -> i64 {
    if input.is_null() || !(1..=MAX_INPUT_LENGTH).contains(&input_length) { return -1; }
    let dimension_value = unsafe { *input };
    if !dimension_value.is_finite() || dimension_value.fract() != 0.0 ||
        !(1.0..=MAX_DIMENSION as f64).contains(&dimension_value) { return -1; }
    let dimension = dimension_value as usize;
    let expected_length = 1 + dimension * dimension + 2 * dimension;
    if input_length != expected_length { return -1; }

    let mut coefficients = [0.0_f64; MAX_OUTPUT_ELEMENTS + 2 * MAX_DIMENSION];
    for index in 0..expected_length - 1 {
        let value = unsafe { *input.add(1 + index) };
        if !value.is_finite() || value.fract() != 0.0 || !(-2.0..=2.0).contains(&value) {
            return -1;
        }
        coefficients[index] = value;
    }
    let matrix_elements = dimension * dimension;
    let mut matrix = [[0.0_f64; MAX_DIMENSION]; MAX_DIMENSION];
    let mut u = [0.0_f64; MAX_DIMENSION];
    let mut v = [0.0_f64; MAX_DIMENSION];
    for row in 0..dimension {
        for column in 0..dimension {
            matrix[row][column] = coefficients[row * dimension + column];
        }
    }
    for index in 0..dimension {
        u[index] = coefficients[matrix_elements + index];
        v[index] = coefficients[matrix_elements + dimension + index];
    }

    let mut right = [0.0_f64; MAX_DIMENSION];
    for column in 0..dimension {
        for inner in 0..dimension {
            right[column] += v[inner] * matrix[inner][column];
        }
    }
    let mut denominator = 0.0_f64;
    for inner in 0..dimension {
        denominator += right[inner] * u[inner];
    }
    denominator += 1.0;

    let mut updated = [0.0_f64; MAX_OUTPUT_ELEMENTS];
    if denominator != 0.0 {
        let mut left = [0.0_f64; MAX_DIMENSION];
        for row in 0..dimension {
            for inner in 0..dimension {
                left[row] += matrix[row][inner] * u[inner];
            }
        }
        let reciprocal = 1.0 / denominator;
        for row in 0..dimension {
            for column in 0..dimension {
                let outer_product = left[row] * right[column];
                let scaled_product = outer_product * reciprocal;
                updated[row * dimension + column] = matrix[row][column] - scaled_product;
            }
        }
    }
    if output.is_null() { return -2; }
    if denominator == 0.0 { return 0; }
    if output_capacity < dimension * dimension { return -2; }
    for index in 0..dimension * dimension {
        unsafe { *output.add(index) = updated[index]; }
    }
    dimension as i64 * dimension as i64
}
