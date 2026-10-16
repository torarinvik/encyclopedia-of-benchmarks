const MAX_DIMENSION: i64 = 32;
const MAX_INPUT_LENGTH: usize = 2053;

/// Compare two bounded row-major integer matrices.
#[no_mangle]
pub unsafe extern "C" fn checkequal(values: *const i64, length: usize) -> i64 {
    if values.is_null() || length < 4 || length > MAX_INPUT_LENGTH {
        return -1;
    }
    let input = std::slice::from_raw_parts(values, length);

    let rows_a = input[0];
    let columns_a = input[1];
    let rows_b = input[2];
    let columns_b = input[3];
    if !(0..=MAX_DIMENSION).contains(&rows_a)
        || !(0..=MAX_DIMENSION).contains(&columns_a)
        || !(0..=MAX_DIMENSION).contains(&rows_b)
        || !(0..=MAX_DIMENSION).contains(&columns_b)
    {
        return -1;
    }

    let count_a = (rows_a * columns_a) as usize;
    let count_b = (rows_b * columns_b) as usize;
    if length != 4 + count_a + count_b {
        return -1;
    }
    if rows_a != rows_b || columns_a != columns_b {
        return 0;
    }
    for index in 0..count_a {
        if input[4 + index] != input[4 + count_a + index] {
            return 0;
        }
    }
    1
}
