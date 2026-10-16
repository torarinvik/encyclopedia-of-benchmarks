const MODULUS: i64 = 1_000_000_007;
const MAX_INPUT_LENGTH: usize = 24;

fn multiply_matrix(left: &[i64; 16], right: &[i64; 16], dimension: usize) -> [i64; 16] {
    let mut output = [0_i64; 16];
    for row in 0..dimension {
        for column in 0..dimension {
            let mut value = 0_i64;
            for inner in 0..dimension {
                value = (value + (left[row * dimension + inner] % MODULUS)
                    * (right[inner * dimension + column] % MODULUS) % MODULUS) % MODULUS;
            }
            output[row * dimension + column] = value;
        }
    }
    output
}

fn matrix_power(matrix: [i64; 16], dimension: usize, initial_power: i64) -> [i64; 16] {
    if matrix[..dimension * dimension].iter().all(|value| *value == 0) {
        return [0_i64; 16];
    }
    let mut result = [0_i64; 16];
    let mut base = matrix;
    for index in 0..dimension {
        result[index * dimension + index] = 1;
    }
    let mut power = initial_power;
    while power > 0 {
        if (power & 1) != 0 {
            result = multiply_matrix(&result, &base, dimension);
        }
        power /= 2;
        base = multiply_matrix(&base, &base, dimension);
    }
    result
}

#[no_mangle]
pub unsafe extern "C" fn linear_recurrence_matrix(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 3 || length > MAX_INPUT_LENGTH {
        return -1;
    }
    let values = std::slice::from_raw_parts(input, length);
    let (dimension_value, nth_term, constant_or_sum_included) = (values[0], values[1], values[2]);
    if !(1..=4).contains(&dimension_value) || !(0..=1_000_000).contains(&nth_term)
        || !(0..=1).contains(&constant_or_sum_included)
    {
        return -1;
    }
    let dimension = dimension_value as usize;
    let matrix_count = dimension * dimension;
    if length != 3 + matrix_count + dimension
        || (constant_or_sum_included == 1 && nth_term < dimension_value - 1)
    {
        return -1;
    }

    let mut matrix = [0_i64; 16];
    let mut base_row = [0_i64; 4];
    for index in 0..matrix_count + dimension {
        let value = values[3 + index];
        if !(0..MODULUS).contains(&value) {
            return -1;
        }
        if index < matrix_count {
            matrix[index] = value;
        } else {
            base_row[index - matrix_count] = value;
        }
    }
    if nth_term < dimension_value - constant_or_sum_included {
        return base_row[(nth_term - constant_or_sum_included) as usize];
    }

    if matrix[..matrix_count].iter().all(|value| *value == 0) {
        return 0;
    }
    let power = nth_term - dimension_value + 1 + constant_or_sum_included;
    let result = matrix_power(matrix, dimension, power);
    let mut value = 0_i64;
    for index in 0..dimension {
        value = (value + (base_row[index] % MODULUS)
            * (result[index * dimension + dimension - 1] % MODULUS) % MODULUS) % MODULUS;
    }
    value
}
