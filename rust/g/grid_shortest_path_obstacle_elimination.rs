const MAX_STATES: usize = 252;

#[no_mangle]
pub unsafe extern "C" fn grid_shortest_path_obstacle_elimination(
    values: *const i64,
    length: usize,
) -> i64 {
    if values.is_null() || !(3..=40).contains(&length) {
        return -2;
    }
    let input = unsafe { std::slice::from_raw_parts(values, length) };
    let rows = input[0];
    let columns = input[1];
    let budget = input[2];
    if !(1..=6).contains(&rows)
        || !(1..=6).contains(&columns)
        || !(0..=6).contains(&budget)
        || length != (3 + rows * columns) as usize
    {
        return -2;
    }
    let cell_count = (rows * columns) as usize;
    let mut cells = [0i64; 36];
    for cell in 0..cell_count {
        let value = input[3 + cell];
        if value != 0 && value != 1 {
            return -2;
        }
        cells[cell] = value;
    }
    if cells[0] != 0 || cells[cell_count - 1] != 0 {
        return -2;
    }

    let stride = (budget + 1) as usize;
    let mut queue = [0usize; MAX_STATES];
    let mut distance = [-1i64; MAX_STATES];
    let start = budget as usize;
    let (mut head, mut tail) = (0usize, 1usize);
    queue[0] = start;
    distance[start] = 0;

    while head < tail {
        let state = queue[head];
        head += 1;
        let cell = state / stride;
        let remaining = (state % stride) as i64;
        if cell + 1 == cell_count {
            return distance[state];
        }
        let row = (cell / columns as usize) as i64;
        let column = (cell % columns as usize) as i64;
        let next_rows = [row - 1, row, row, row + 1];
        let next_columns = [column, column - 1, column + 1, column];
        for direction in 0..4 {
            let next_row = next_rows[direction];
            let next_column = next_columns[direction];
            if next_row < 0 || next_row >= rows || next_column < 0 || next_column >= columns {
                continue;
            }
            let next_cell = (next_row * columns + next_column) as usize;
            let next_remaining = remaining - cells[next_cell];
            if next_remaining < 0 {
                continue;
            }
            let next_state = next_cell * stride + next_remaining as usize;
            if distance[next_state] != -1 {
                continue;
            }
            distance[next_state] = distance[state] + 1;
            queue[tail] = next_state;
            tail += 1;
        }
    }
    -1
}
