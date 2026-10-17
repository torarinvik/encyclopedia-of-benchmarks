const INVALID_RESULT: i64 = -1;
const OUTPUT_ERROR: i64 = -2;
const MAX_INPUT_VALUES: usize = 11;
const MAX_OUTPUT_BYTES: usize = 72;
const COEFFICIENT_LIMIT: i64 = 32;
const COEFFICIENT_SCALE: f64 = 16.0;

#[inline(never)]
fn rounded_multiply(left: f64, right: f64) -> f64 { left * right }

#[inline(never)]
fn rounded_subtract(left: f64, right: f64) -> f64 { left - right }

#[inline(never)]
fn rounded_divide(left: f64, right: f64) -> f64 { left / right }

fn valid_dominance(matrix: &[f64; 9], dimension: usize) -> bool {
    let mut seen = [false; 3];
    for row in 0..dimension {
        let mut dominant_column = None;
        for column in 0..dimension {
            let mut other_sum = 0.0;
            for other in 0..dimension {
                if other != column {
                    other_sum += matrix[row * dimension + other].abs();
                }
            }
            if matrix[row * dimension + column].abs() > other_sum {
                if dominant_column.is_some() { return false; }
                dominant_column = Some(column);
            }
        }
        let Some(column) = dominant_column else { return false; };
        if seen[column] { return false; }
        seen[column] = true;
    }
    true
}

fn invert(matrix: &mut [f64; 9], dimension: usize) -> [f64; 9] {
    let mut inverse = [0.0_f64; 9];
    let mut identity = [0.0_f64; 9];
    let mut index = [0_usize; 3];
    let mut scale = [0.0_f64; 3];
    for row in 0..dimension {
        index[row] = row;
        identity[row * dimension + row] = 1.0;
        for column in 0..dimension {
            let coefficient = matrix[row * dimension + column].abs();
            if coefficient > scale[row] { scale[row] = coefficient; }
        }
    }
    for column in 0..dimension - 1 {
        let mut best_ratio = 0.0;
        let mut pivot_slot = column;
        for slot in column..dimension {
            let row = index[slot];
            let ratio = rounded_divide(matrix[row * dimension + column].abs(), scale[row]);
            if ratio > best_ratio {
                best_ratio = ratio;
                pivot_slot = slot;
            }
        }
        index.swap(column, pivot_slot);
        let pivot_row = index[column];
        for slot in column + 1..dimension {
            let row = index[slot];
            let ratio = rounded_divide(matrix[row * dimension + column], matrix[pivot_row * dimension + column]);
            matrix[row * dimension + column] = ratio;
            for trailing in column + 1..dimension {
                let product = rounded_multiply(ratio, matrix[pivot_row * dimension + trailing]);
                matrix[row * dimension + trailing] =
                    rounded_subtract(matrix[row * dimension + trailing], product);
            }
        }
    }
    for pivot in 0..dimension - 1 {
        for row_slot in pivot + 1..dimension {
            let row = index[row_slot];
            let pivot_row = index[pivot];
            for rhs in 0..dimension {
                let product = rounded_multiply(
                    matrix[row * dimension + pivot], identity[pivot_row * dimension + rhs]);
                identity[row * dimension + rhs] =
                    rounded_subtract(identity[row * dimension + rhs], product);
            }
        }
    }
    for rhs in 0..dimension {
        let last_row = index[dimension - 1];
        inverse[(dimension - 1) * dimension + rhs] =
            rounded_divide(identity[last_row * dimension + rhs], matrix[last_row * dimension + dimension - 1]);
        for row in (0..dimension - 1).rev() {
            let source_row = index[row];
            let mut value = identity[source_row * dimension + rhs];
            for column in row + 1..dimension {
                let product = rounded_multiply(
                    matrix[source_row * dimension + column], inverse[column * dimension + rhs]);
                value = rounded_subtract(value, product);
            }
            inverse[row * dimension + rhs] = rounded_divide(value, matrix[source_row * dimension + row]);
        }
    }
    inverse
}

unsafe fn put_f64_le(output: *mut u8, offset: usize, value: f64) {
    let mut bits = value.to_bits();
    for byte in 0..8 {
        *output.add(offset + byte) = bits as u8;
        bits >>= 8;
    }
}

#[no_mangle]
pub unsafe extern "C" fn inverse_of_matrix(
    input: *const i64,
    length: usize,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if input.is_null() || length < 1 || length > MAX_INPUT_VALUES { return INVALID_RESULT; }
    let dimension_value = *input;
    if dimension_value != 2 && dimension_value != 3 { return INVALID_RESULT; }
    let dimension = dimension_value as usize;
    if length != 1 + dimension * dimension { return INVALID_RESULT; }

    let mut matrix = [0.0_f64; 9];
    for index in 0..dimension * dimension {
        let coefficient = *input.add(index + 1);
        if !(-COEFFICIENT_LIMIT..=COEFFICIENT_LIMIT).contains(&coefficient) {
            return INVALID_RESULT;
        }
        matrix[index] = coefficient as f64 / COEFFICIENT_SCALE;
    }
    if !valid_dominance(&matrix, dimension) { return INVALID_RESULT; }

    let inverse = invert(&mut matrix, dimension);
    for index in 0..dimension * dimension {
        if !inverse[index].is_finite() || inverse[index].abs() > 32768.0 {
            return INVALID_RESULT;
        }
    }
    let output_bytes = dimension * dimension * 8;
    if output_bytes > MAX_OUTPUT_BYTES { return INVALID_RESULT; }
    if output.is_null() || output_capacity < output_bytes { return OUTPUT_ERROR; }
    for index in 0..dimension * dimension {
        put_f64_le(output, index * 8, inverse[index]);
    }
    output_bytes as i64
}
