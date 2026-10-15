#[no_mangle]
pub unsafe extern "C" fn count_negative_numbers_in_sorted_matrix(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 3 || length > 514 {
        return -1;
    }
    let rows_value = *input;
    let columns_value = *input.add(1);
    if !(1..=512).contains(&rows_value) || !(1..=512).contains(&columns_value) {
        return -1;
    }
    let rows = rows_value as usize;
    let columns = columns_value as usize;
    if rows * columns > 512 || length != 2 + rows * columns {
        return -1;
    }

    let mut nonnegative = 0usize;
    let mut bound = columns;
    for row in 0..rows {
        let mut left = 0usize;
        let mut right = bound;
        while left < right {
            let middle = left + (right - left) / 2;
            let value = *input.add(2 + row * columns + middle);
            if value >= 0 {
                left = middle + 1;
            } else {
                right = middle;
            }
        }
        bound = left;
        nonnegative += bound;
    }
    (rows * columns - nonnegative) as i64
}
