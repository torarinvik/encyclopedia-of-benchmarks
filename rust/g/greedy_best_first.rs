const MAX_CELLS: usize = 9;

fn heuristic(cell: usize, goal: usize, columns: usize) -> usize {
    (cell / columns).abs_diff(goal / columns) + (cell % columns).abs_diff(goal % columns)
}

#[no_mangle]
pub unsafe extern "C" fn greedy_best_first(values: *const i64, length: usize) -> i64 {
    if values.is_null() || !(7..=9).contains(&length) { return -1; }
    let values = std::slice::from_raw_parts(values, length);
    let (row_value, column_value) = (values[0], values[1]);
    if !(1..=3).contains(&row_value) || !(1..=3).contains(&column_value) { return -1; }
    let (rows, columns) = (row_value as usize, column_value as usize);
    if length != 6 + rows { return -1; }
    let (start_row, start_column, goal_row, goal_column) = (values[2], values[3], values[4], values[5]);
    if !(0..row_value).contains(&start_row) || !(0..row_value).contains(&goal_row) ||
        !(0..column_value).contains(&start_column) || !(0..column_value).contains(&goal_column) { return -1; }
    let mut masks = [0usize; 3];
    for row in 0..rows {
        let mask = values[6 + row];
        if mask < 0 || mask >= (1i64 << columns) { return -1; }
        masks[row] = mask as usize;
    }
    let start = start_row as usize * columns + start_column as usize;
    let goal = goal_row as usize * columns + goal_column as usize;
    if masks[start / columns] & (1 << (start % columns)) != 0 || masks[goal / columns] & (1 << (goal % columns)) != 0 { return -1; }

    let mut opened = [0usize; MAX_CELLS];
    let mut parent = [-1i32; MAX_CELLS];
    let mut closed = [false; MAX_CELLS];
    let mut in_open = [false; MAX_CELLS];
    opened[0] = start;
    in_open[start] = true;
    let mut open_count = 1usize;
    let mut found = false;
    while open_count > 0 {
        for index in 1..open_count {
            let current = opened[index];
            let mut position = index;
            while position > 0 && heuristic(opened[position - 1], goal, columns) > heuristic(current, goal, columns) {
                opened[position] = opened[position - 1];
                position -= 1;
            }
            opened[position] = current;
        }
        let current = opened[0];
        for index in 1..open_count { opened[index - 1] = opened[index]; }
        open_count -= 1;
        in_open[current] = false;
        if current == goal { found = true; break; }
        closed[current] = true;
        let row = current / columns;
        let column = current % columns;
        let next_rows = [row.wrapping_sub(1), row, row + 1, row];
        let next_columns = [column, column.wrapping_sub(1), column, column + 1];
        for direction in 0..4 {
            let (next_row, next_column) = (next_rows[direction], next_columns[direction]);
            if next_row >= rows || next_column >= columns { continue; }
            let child = next_row * columns + next_column;
            if masks[next_row] & (1 << next_column) != 0 || closed[child] || in_open[child] { continue; }
            parent[child] = current as i32;
            opened[open_count] = child;
            open_count += 1;
            in_open[child] = true;
        }
    }
    let mut path = [0usize; MAX_CELLS];
    let mut path_count = 0usize;
    if found {
        let mut current = goal as i32;
        while current >= 0 && path_count < MAX_CELLS {
            path[path_count] = current as usize;
            path_count += 1;
            current = parent[current as usize];
        }
    } else {
        path[0] = start;
        path_count = 1;
    }
    let mut packed = 0u64;
    for index in 0..path_count { packed |= ((path[path_count - 1 - index] + 1) as u64) << (4 * index); }
    (((path_count as u64) << 36) | packed) as i64
}
