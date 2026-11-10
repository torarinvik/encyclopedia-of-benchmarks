/// Minimize grid-cell and transition costs using two rows of dynamic programming.
#[no_mangle]
pub unsafe extern "C" fn minimum_path_cost_in_grid(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 2 { return -1; }
    let row_arg = *input;
    let column_arg = *input.add(1);
    if !(1..=32).contains(&row_arg) || !(1..=32).contains(&column_arg) { return -1; }
    let rows = row_arg as usize;
    let columns = column_arg as usize;
    let cells = rows * columns;
    let move_offset = 2 + cells;
    if length != move_offset + cells * columns { return -1; }
    for index in 0..cells {
        let value = *input.add(2 + index);
        if value < 0 || value >= cells as i64 { return -1; }
    }
    for index in 0..cells * columns {
        let cost = *input.add(move_offset + index);
        if !(1..=100).contains(&cost) { return -1; }
    }
    let mut costs = [0u32; 32];
    let mut next_costs = [0u32; 32];
    for row in 0..rows - 1 {
        next_costs.fill(65536);
        for column in 0..columns {
            let value = *input.add(2 + row * columns + column) as usize;
            let base = costs[column] + value as u32;
            for target in 0..columns {
                let candidate = base + *input.add(move_offset + value * columns + target) as u32;
                next_costs[target] = candidate.min(next_costs[target]);
            }
        }
        costs = next_costs;
    }
    let last_row = 2 + (rows - 1) * columns;
    let mut minimum = 65536u32;
    for column in 0..columns {
        let candidate = costs[column] + *input.add(last_row + column) as u32;
        if candidate < minimum { minimum = candidate; }
    }
    i64::from(minimum)
}
