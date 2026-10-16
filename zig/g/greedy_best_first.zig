const MAX_CELLS: usize = 9;

fn heuristic(cell: usize, goal: usize, columns: usize) usize {
    const row = cell / columns;
    const column = cell % columns;
    const goal_row = goal / columns;
    const goal_column = goal % columns;
    return (if (row > goal_row) row - goal_row else goal_row - row) +
        (if (column > goal_column) column - goal_column else goal_column - column);
}

export fn greedy_best_first(input: [*c]const i64, length: usize) i64 {
    if (input == null or length < 7 or length > 9) return -1;
    const values = input;
    const row_value = values[0];
    const column_value = values[1];
    if (row_value < 1 or row_value > 3 or column_value < 1 or column_value > 3) return -1;
    const rows: usize = @intCast(row_value);
    const columns: usize = @intCast(column_value);
    if (length != 6 + rows) return -1;
    const start_row = values[2];
    const start_column = values[3];
    const goal_row = values[4];
    const goal_column = values[5];
    if (start_row < 0 or start_row >= row_value or goal_row < 0 or goal_row >= row_value or
        start_column < 0 or start_column >= column_value or goal_column < 0 or goal_column >= column_value) return -1;
    var masks: [3]usize = @splat(0);
    for (0..rows) |row| {
        const mask = values[6 + row];
        if (mask < 0 or mask >= (@as(i64, 1) << @intCast(columns))) return -1;
        masks[row] = @intCast(mask);
    }
    const start: usize = @intCast(start_row * column_value + start_column);
    const goal: usize = @intCast(goal_row * column_value + goal_column);
    if (masks[start / columns] & (@as(usize, 1) << @intCast(start % columns)) != 0 or
        masks[goal / columns] & (@as(usize, 1) << @intCast(goal % columns)) != 0) return -1;

    var opened: [MAX_CELLS]usize = @splat(0);
    var parent: [MAX_CELLS]i32 = @splat(-1);
    var closed: [MAX_CELLS]bool = @splat(false);
    var in_open: [MAX_CELLS]bool = @splat(false);
    opened[0] = start;
    in_open[start] = true;
    var open_count: usize = 1;
    var found = false;
    while (open_count > 0) {
        for (1..open_count) |index| {
            const current = opened[index];
            var position = index;
            while (position > 0 and heuristic(opened[position - 1], goal, columns) > heuristic(current, goal, columns)) {
                opened[position] = opened[position - 1];
                position -= 1;
            }
            opened[position] = current;
        }
        const current = opened[0];
        for (1..open_count) |index| opened[index - 1] = opened[index];
        open_count -= 1;
        in_open[current] = false;
        if (current == goal) { found = true; break; }
        closed[current] = true;
        const row = current / columns;
        const column = current % columns;
        const next_rows = [4]usize{ row -% 1, row, row + 1, row };
        const next_columns = [4]usize{ column, column -% 1, column, column + 1 };
        for (0..4) |direction| {
            const next_row = next_rows[direction];
            const next_column = next_columns[direction];
            if (next_row >= rows or next_column >= columns) continue;
            const child = next_row * columns + next_column;
            if (masks[next_row] & (@as(usize, 1) << @intCast(next_column)) != 0 or closed[child] or in_open[child]) continue;
            parent[child] = @intCast(current);
            opened[open_count] = child;
            open_count += 1;
            in_open[child] = true;
        }
    }
    var path: [MAX_CELLS]usize = @splat(0);
    var path_count: usize = 0;
    if (found) {
        var current: i32 = @intCast(goal);
        while (current >= 0 and path_count < MAX_CELLS) {
            path[path_count] = @intCast(current);
            path_count += 1;
            current = parent[@intCast(current)];
        }
    } else {
        path[0] = start;
        path_count = 1;
    }
    var packed: u64 = 0;
    for (0..path_count) |index| packed |= @as(u64, @intCast(path[path_count - 1 - index] + 1)) << @intCast(4 * index);
    return @intCast((@as(u64, @intCast(path_count)) << 36) | packed);
}
