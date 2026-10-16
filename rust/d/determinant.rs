const MAX_DIMENSION: usize = 6;
const MAX_INPUT_LENGTH: usize = 1 + MAX_DIMENSION * MAX_DIMENSION;
const INVALID_RESULT: i64 = i64::MIN;

fn determinant_recursive(matrix: &[i64], dimension: usize) -> i64 {
    if dimension == 1 {
        return matrix[0];
    }

    let mut result = 0i64;
    let mut minor = [0i64; (MAX_DIMENSION - 1) * (MAX_DIMENSION - 1)];
    for column in 0..dimension {
        let mut minor_index = 0;
        for row in 1..dimension {
            for source_column in 0..dimension {
                if source_column != column {
                    minor[minor_index] = matrix[row * dimension + source_column];
                    minor_index += 1;
                }
            }
        }
        let term = matrix[column] * determinant_recursive(&minor[..minor_index], dimension - 1);
        result += if column % 2 == 0 { term } else { -term };
    }
    result
}

#[no_mangle]
pub unsafe extern "C" fn determinant(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 1 || length > MAX_INPUT_LENGTH {
        return INVALID_RESULT;
    }
    let values = unsafe { core::slice::from_raw_parts(input, length) };
    let dimension_value = values[0];
    if !(1..=MAX_DIMENSION as i64).contains(&dimension_value) {
        return INVALID_RESULT;
    }
    let dimension = dimension_value as usize;
    if length != 1 + dimension * dimension || values[1..].iter().any(|value| !(-9..=9).contains(value)) {
        return INVALID_RESULT;
    }
    determinant_recursive(&values[1..], dimension)
}
