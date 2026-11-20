const MAX_ROWS: usize = 6;
const MAX_COLUMNS: usize = 6;
const MAX_COLORS: usize = 6;
const COLOR_SIDE: usize = 7;
const MAX_PARSEABLE_LENGTH: usize = 39;

fn solve(input: &[i64]) -> i64 {
    if input.len() < 2 || input.len() > MAX_PARSEABLE_LENGTH { return -1; }
    let rows_raw = input[0];
    let columns_raw = input[1];
    if rows_raw < 1 || rows_raw > MAX_ROWS as i64
        || columns_raw < 1 || columns_raw > MAX_COLUMNS as i64 { return -1; }
    let rows = rows_raw as usize;
    let columns = columns_raw as usize;
    if input.len() != 2 + rows * columns
        || input[2..].iter().any(|&color| !(1..=MAX_COLORS as i64).contains(&color)) {
        return -1;
    }

    let mut first_row = [rows_raw; COLOR_SIDE];
    let mut last_row = [-1_i64; COLOR_SIDE];
    let mut first_column = [columns_raw; COLOR_SIDE];
    let mut last_column = [-1_i64; COLOR_SIDE];
    let mut outgoing = [0_i64; COLOR_SIDE];
    let mut indegree = [0_i64; COLOR_SIDE];
    let mut queue = [0_i64; COLOR_SIDE];
    for row in 0..rows {
        for column in 0..columns {
            let color = input[2 + row * columns + column] as usize;
            first_row[color] = first_row[color].min(row as i64);
            last_row[color] = last_row[color].max(row as i64);
            first_column[color] = first_column[color].min(column as i64);
            last_column[color] = last_column[color].max(column as i64);
        }
    }

    let mut present_count = 0_i64;
    for color in 1..=MAX_COLORS {
        if last_row[color] < 0 { continue; }
        present_count += 1;
        for row in first_row[color] as usize..=last_row[color] as usize {
            for column in first_column[color] as usize..=last_column[color] as usize {
                let covered = input[2 + row * columns + column] as usize;
                let bit = 1_i64 << covered;
                if covered != color && outgoing[color] & bit == 0 {
                    outgoing[color] |= bit;
                    indegree[covered] += 1;
                }
            }
        }
    }
    let mut head = 0;
    let mut tail = 0;
    for color in 1..=MAX_COLORS {
        if last_row[color] >= 0 && indegree[color] == 0 {
            queue[tail] = color as i64;
            tail += 1;
        }
    }
    let mut processed = 0_i64;
    while head < tail {
        let color = queue[head] as usize;
        head += 1;
        processed += 1;
        for later in 1..=MAX_COLORS {
            if outgoing[color] & (1_i64 << later) != 0 {
                indegree[later] -= 1;
                if indegree[later] == 0 {
                    queue[tail] = later as i64;
                    tail += 1;
                }
            }
        }
    }
    if processed == present_count { 1 } else { 0 }
}

#[no_mangle]
pub unsafe extern "C" fn strange_printer_ii(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 2 || length > MAX_PARSEABLE_LENGTH { return -1; }
    solve(std::slice::from_raw_parts(input, length))
}
