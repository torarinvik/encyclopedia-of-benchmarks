const MAX_ROWS: usize = 16;
const MAX_COLUMNS: usize = 16;

fn solve(values: &[i64]) -> i64 {
    if values.len() < 2 || values.len() > 259 { return -1; }
    if !(1..=MAX_ROWS as i64).contains(&values[0])
        || !(1..=MAX_COLUMNS as i64).contains(&values[1]) { return -1; }
    let rows = values[0] as usize;
    let columns = values[1] as usize;
    if values.len() != 2 + rows * columns { return -1; }
    if values[2..].iter().any(|&cell| cell != 0 && cell != 1) { return -1; }

    let mut last_one = [-1_i64; MAX_COLUMNS];
    let mut left = [-1_i64; MAX_COLUMNS];
    let mut right = [0_i64; MAX_COLUMNS];
    let mut stack = [0_usize; MAX_COLUMNS];
    let mut best = 0_i64;
    for row in 0..rows {
        for column in 0..columns {
            if values[2 + row * columns + column] == 1 { last_one[column] = row as i64; }
        }
        let mut top = 0_usize;
        for column in 0..columns {
            while top > 0 && last_one[stack[top - 1]] <= last_one[column] { top -= 1; }
            left[column] = if top == 0 { -1 } else { stack[top - 1] as i64 };
            stack[top] = column;
            top += 1;
        }
        top = 0;
        for cursor in (0..columns).rev() {
            while top > 0 && last_one[stack[top - 1]] <= last_one[cursor] { top -= 1; }
            right[cursor] = if top == 0 { columns as i64 } else { stack[top - 1] as i64 };
            stack[top] = cursor;
            top += 1;
        }
        for column in 0..columns {
            let height = row as i64 - last_one[column];
            let width = right[column] - left[column] - 1;
            best = best.max(height * width);
        }
    }
    best
}

#[no_mangle]
pub unsafe extern "C" fn largest_zero_submatrix(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 2 || length > 259 { return -1; }
    solve(std::slice::from_raw_parts(input, length))
}
