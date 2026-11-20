const MAX_N: usize = 8;

#[no_mangle]
pub unsafe extern "C" fn rsk_row_insertion(input: *const i64, length: usize) -> i64 {
    if input.is_null() || !(1..=MAX_N + 2).contains(&length) { return i64::MIN; }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    let n_value = values[0];
    if n_value < 0 || n_value > MAX_N as i64 || length != n_value as usize + 1 { return i64::MIN; }
    let n = n_value as usize;

    let mut seen = [false; MAX_N];
    for &value in &values[1..] {
        if value < 0 || value >= n_value || seen[value as usize] { return i64::MIN; }
        seen[value as usize] = true;
    }
    if n == 0 { return 0; }

    let mut p = [0i64; MAX_N * MAX_N];
    let mut q = [0i64; MAX_N * MAX_N];
    let mut row_lengths = [0usize; MAX_N];
    let mut row_count = 0usize;
    for step in 1..=n {
        let mut value = values[step] + 1;
        let mut row = 0usize;
        loop {
            if row == row_count {
                p[row * MAX_N] = value;
                q[row * MAX_N] = step as i64;
                row_lengths[row] = 1;
                row_count += 1;
                break;
            }
            let mut column = 0usize;
            while column < row_lengths[row] && p[row * MAX_N + column] < value { column += 1; }
            if column == row_lengths[row] {
                p[row * MAX_N + column] = value;
                q[row * MAX_N + column] = step as i64;
                row_lengths[row] += 1;
                break;
            }
            let bumped = p[row * MAX_N + column];
            p[row * MAX_N + column] = value;
            value = bumped;
            row += 1;
        }
    }

    let mut p_row = [0i64; MAX_N];
    let mut q_row = [0i64; MAX_N];
    for row in 0..row_count {
        for column in 0..row_lengths[row] {
            p_row[p[row * MAX_N + column] as usize - 1] = row as i64;
            q_row[q[row * MAX_N + column] as usize - 1] = row as i64;
        }
    }
    let mut code = n_value;
    for label in 0..n {
        code = code * 9 + p_row[label] + 1;
        code = code * 9 + q_row[label] + 1;
    }
    code
}
