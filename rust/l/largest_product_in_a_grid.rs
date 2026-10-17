const MAX_INPUT_LENGTH: usize = 3971;
const INVALID_RESULT: i64 = -1;

#[no_mangle]
pub unsafe extern "C" fn largest_product_in_a_grid(values: *const i64, length: usize) -> i64 {
    if values.is_null() || length < 2 || length > MAX_INPUT_LENGTH {
        return INVALID_RESULT;
    }
    let input = unsafe { std::slice::from_raw_parts(values, length) };
    let rows = input[0];
    let cols = input[1];
    if !(0..=63).contains(&rows) || !(0..=63).contains(&cols) {
        return INVALID_RESULT;
    }

    let row_count = rows as usize;
    let col_count = cols as usize;
    if length != 2 + row_count * col_count {
        return INVALID_RESULT;
    }
    let cells = &input[2..];
    if cells.iter().any(|&value| !(0..=1000).contains(&value)) {
        return INVALID_RESULT;
    }

    let row_steps = [0i64, 1, 1, 1];
    let col_steps = [1i64, 0, 1, -1];
    let mut best = 0i64;
    for row in 0..row_count {
        for col in 0..col_count {
            for direction in 0..4 {
                let mut product = 1i64;
                for offset in 0..4 {
                    let next_row = row as i64 + offset as i64 * row_steps[direction];
                    let next_col = col as i64 + offset as i64 * col_steps[direction];
                    if next_row < 0 || next_row >= rows || next_col < 0 || next_col >= cols {
                        product = 0;
                        break;
                    }
                    let index = next_row as usize * col_count + next_col as usize;
                    product *= cells[index];
                }
                best = best.max(product);
            }
        }
    }
    best
}
