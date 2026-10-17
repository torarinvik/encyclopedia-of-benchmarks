const MAX_INPUT_LENGTH: usize = 18;
const MAX_DIMENSION: usize = 4;

fn exact_integer(value: f64, minimum: i64, maximum: i64) -> Option<i64> {
    if !value.is_finite() || value.trunc() != value || value < minimum as f64 || value > maximum as f64 {
        return None;
    }
    Some(value as i64)
}

#[no_mangle]
pub unsafe extern "C" fn lu_pivot_decomposition(
    input: *const f64,
    input_length: usize,
    output: *mut f64,
    output_capacity: usize,
) -> i64 {
    if input.is_null() || input_length < 1 || input_length > MAX_INPUT_LENGTH {
        return -1;
    }
    let dimension = match exact_integer(*input, 1, MAX_DIMENSION as i64) {
        Some(value) => value as usize,
        None => return -1,
    };
    let matrix_elements = dimension * dimension;
    if input_length != 1 + matrix_elements {
        return -1;
    }

    let mut packed_lu = [0.0_f64; 16];
    for index in 0..matrix_elements {
        let value = *input.add(index + 1);
        if exact_integer(value, -8, 8).is_none() {
            return -1;
        }
        packed_lu[index] = value;
    }
    let mut pivot = [0_i64; 5];
    for index in 0..=dimension {
        pivot[index] = index as i64;
    }

    for column in 0..dimension {
        let mut max_value = 0.0_f64;
        let mut max_index = column;
        for row in column..dimension {
            let magnitude = packed_lu[row * dimension + column].abs();
            if magnitude > max_value {
                max_value = magnitude;
                max_index = row;
            }
        }
        if max_index != column {
            pivot.swap(column, max_index);
            for swap_column in 0..dimension {
                packed_lu.swap(column * dimension + swap_column, max_index * dimension + swap_column);
            }
            pivot[dimension] += 1;
        }

        let pivot_value = packed_lu[column * dimension + column];
        if pivot_value == 0.0 || !pivot_value.is_finite() {
            return -1;
        }
        for row in column + 1..dimension {
            let multiplier_index = row * dimension + column;
            packed_lu[multiplier_index] /= pivot_value;
            if !packed_lu[multiplier_index].is_finite() {
                return -1;
            }
            for trailing_column in column + 1..dimension {
                let index = row * dimension + trailing_column;
                packed_lu[index] -= packed_lu[multiplier_index]
                    * packed_lu[column * dimension + trailing_column];
                if !packed_lu[index].is_finite() {
                    return -1;
                }
            }
        }
    }

    let output_length = matrix_elements + dimension + 1;
    if output.is_null() || output_capacity < output_length {
        return -2;
    }
    for index in 0..matrix_elements {
        *output.add(index) = packed_lu[index];
    }
    for index in 0..=dimension {
        *output.add(matrix_elements + index) = pivot[index] as f64;
    }
    output_length as i64
}
