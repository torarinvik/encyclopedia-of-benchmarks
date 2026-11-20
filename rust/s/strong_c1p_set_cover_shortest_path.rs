const MAX_ROWS: usize = 8;
const MAX_COLUMNS: usize = 10;
const MAX_INPUT: usize = 21;
const INF: i64 = 1_000_000_000;

fn solve(
    rows: usize,
    columns: usize,
    weights: &[i64; MAX_COLUMNS],
    row_left: &[usize; MAX_ROWS],
    row_right: &[usize; MAX_ROWS],
) -> i64 {
    let mut order = [0usize; MAX_ROWS];
    for row in 0..rows { order[row] = row; }
    for i in 1..rows {
        let value = order[i];
        let mut j = i;
        while j > 0 && row_left[order[j - 1]] > row_left[value] {
            order[j] = order[j - 1];
            j -= 1;
        }
        order[j] = value;
    }

    let mut grouped_left = [0usize; MAX_ROWS];
    let mut grouped_right = [0usize; MAX_ROWS];
    let mut groups = 0usize;
    for i in 0..rows {
        let row = order[i];
        if groups == 0 || grouped_left[groups - 1] != row_left[row] {
            grouped_left[groups] = row_left[row];
            grouped_right[groups] = row_right[row];
            groups += 1;
        } else if row_right[row] < grouped_right[groups - 1] {
            grouped_right[groups - 1] = row_right[row];
        }
    }
    let mut retained_left = [0usize; MAX_ROWS];
    let mut retained_right = [0usize; MAX_ROWS];
    let mut retained = 0usize;
    let mut suffix_minimum = columns;
    for i in (0..groups).rev() {
        if grouped_right[i] < suffix_minimum {
            retained_left[retained] = grouped_left[i];
            retained_right[retained] = grouped_right[i];
            retained += 1;
            suffix_minimum = grouped_right[i];
        }
    }

    let mut column_start = [-1i32; MAX_COLUMNS];
    let mut column_end = [-1i32; MAX_COLUMNS];
    for reduced_row in 0..retained {
        let source = retained - 1 - reduced_row;
        for column in retained_left[source]..=retained_right[source] {
            if column_start[column] < 0 { column_start[column] = reduced_row as i32; }
            column_end[column] = reduced_row as i32;
        }
    }

    let mut distance = [INF; MAX_COLUMNS];
    for column in 0..columns {
        if column_start[column] == 0 { distance[column] = 0; }
    }
    let mut best = INF;
    for from in 0..columns {
        if distance[from] == INF { continue; }
        if column_end[from] == retained as i32 - 1 {
            best = best.min(distance[from] + weights[from]);
        }
        for to in from + 1..columns {
            if column_start[to] >= 0 && column_start[to] <= column_end[from] + 1 {
                distance[to] = distance[to].min(distance[from] + weights[from]);
            }
        }
    }
    if best == INF { -1 } else { best }
}

#[no_mangle]
pub unsafe extern "C" fn strong_c1p_set_cover_shortest_path(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input.is_null() || length < 4 || length > MAX_INPUT { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let rows_raw = values[0];
    let columns_raw = values[1];
    if !(1..=MAX_ROWS as i64).contains(&rows_raw)
        || !(1..=MAX_COLUMNS as i64).contains(&columns_raw) { return -1; }
    let rows = rows_raw as usize;
    let columns = columns_raw as usize;
    if length != 2 + rows + columns { return -1; }
    let mut weights = [0i64; MAX_COLUMNS];
    for column in 0..columns {
        let weight = values[2 + column];
        if !(1..=20).contains(&weight) { return -1; }
        weights[column] = weight;
    }
    let allowed = (1u64 << columns) - 1;
    let mut masks = [0u64; MAX_ROWS];
    let mut row_left = [0usize; MAX_ROWS];
    let mut row_right = [0usize; MAX_ROWS];
    let mut infeasible = false;
    for row in 0..rows {
        let raw = values[2 + columns + row];
        if raw < 0 || raw as u64 & !allowed != 0 { return -1; }
        masks[row] = raw as u64;
        row_left[row] = columns;
        row_right[row] = 0;
        let mut seen_one = false;
        let mut seen_zero_after = false;
        for column in 0..columns {
            if masks[row] & (1u64 << column) != 0 {
                if seen_zero_after { return -1; }
                seen_one = true;
                if row_left[row] == columns { row_left[row] = column; }
                row_right[row] = column;
            } else if seen_one {
                seen_zero_after = true;
            }
        }
        if masks[row] == 0 { infeasible = true; }
    }
    let result = if infeasible { -1 } else { solve(rows, columns, &weights, &row_left, &row_right) };
    if output.is_null() || capacity < 8 { return -2; }
    let bits = result as u64;
    for byte in 0..8 { *output.add(byte) = (bits >> (8 * byte)) as u8; }
    8
}
