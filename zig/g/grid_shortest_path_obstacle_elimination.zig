export fn grid_shortest_path_obstacle_elimination(values: ?[*]const i64, length: usize) i64 {
    if (values == null or length < 3 or length > 40) return -2;
    const input = values.?;
    const rows = input[0];
    const columns = input[1];
    const budget = input[2];
    if (rows < 1 or rows > 6 or columns < 1 or columns > 6 or budget < 0 or budget > 6) return -2;
    if (length != 3 + @as(usize, @intCast(rows * columns))) return -2;

    const cell_count: usize = @intCast(rows * columns);
    var cells: [36]i64 = @splat(0);
    for (0..cell_count) |cell| {
        const value = input[3 + cell];
        if (value != 0 and value != 1) return -2;
        cells[cell] = value;
    }
    if (cells[0] != 0 or cells[cell_count - 1] != 0) return -2;

    const stride: usize = @intCast(budget + 1);
    var queue: [252]usize = @splat(0);
    var distance: [252]i64 = @splat(-1);
    const start: usize = @intCast(budget);
    var head: usize = 0;
    var tail: usize = 1;
    queue[0] = start;
    distance[start] = 0;

    while (head < tail) {
        const state = queue[head];
        head += 1;
        const cell = state / stride;
        const remaining: i64 = @intCast(state % stride);
        if (cell + 1 == cell_count) return distance[state];
        const row: i64 = @intCast(cell / @as(usize, @intCast(columns)));
        const column: i64 = @intCast(cell % @as(usize, @intCast(columns)));
        const next_rows = [_]i64{ row - 1, row, row, row + 1 };
        const next_columns = [_]i64{ column, column - 1, column + 1, column };
        for (0..4) |direction| {
            const next_row = next_rows[direction];
            const next_column = next_columns[direction];
            if (next_row < 0 or next_row >= rows or next_column < 0 or next_column >= columns) continue;
            const next_cell: usize = @intCast(next_row * columns + next_column);
            const next_remaining = remaining - cells[next_cell];
            if (next_remaining < 0) continue;
            const next_state = next_cell * stride + @as(usize, @intCast(next_remaining));
            if (distance[next_state] != -1) continue;
            distance[next_state] = distance[state] + 1;
            queue[tail] = next_state;
            tail += 1;
        }
    }
    return -1;
}
