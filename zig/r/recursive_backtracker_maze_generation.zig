const MAX_CELLS: usize = 64;

export fn recursive_backtracker_maze_generation(input_ptr: ?[*]const i64, length: usize,
    output_ptr: ?[*]u8, capacity: usize) i64 {
    if (input_ptr == null or length < 4 or length > 68) return -1;
    const input = input_ptr.?[0..length];
    const rows_word = input[0];
    const cols_word = input[1];
    const start_word = input[2];
    const draw_count = input[3];
    if (rows_word < 1 or rows_word > 64 or cols_word < 1 or cols_word > 64) return -1;
    const rows: usize = @intCast(rows_word);
    const cols: usize = @intCast(cols_word);
    const cells = rows * cols;
    if (cells > MAX_CELLS or start_word < 0 or @as(u64, @intCast(start_word)) >= cells or
        draw_count != @as(i64, @intCast(cells - 1)) or length != 4 + cells - 1) return -1;
    for (input[4..]) |draw| if (draw < 0 or draw > 3) return -1;

    var visited: [MAX_CELLS]bool = @splat(false);
    var walls: [MAX_CELLS]u8 = @splat(15);
    var stack: [MAX_CELLS]usize = @splat(0);
    var depth: usize = 1;
    var cursor: usize = 0;
    stack[0] = @intCast(start_word);
    visited[stack[0]] = true;
    while (depth > 0) {
        const cell = stack[depth - 1];
        const row = cell / cols;
        const col = cell % cols;
        var next_cells: [4]usize = @splat(0);
        var directions: [4]usize = @splat(0);
        var count: usize = 0;
        if (row > 0 and !visited[cell - cols]) { next_cells[count] = cell - cols; directions[count] = 0; count += 1; }
        if (col + 1 < cols and !visited[cell + 1]) { next_cells[count] = cell + 1; directions[count] = 1; count += 1; }
        if (row + 1 < rows and !visited[cell + cols]) { next_cells[count] = cell + cols; directions[count] = 2; count += 1; }
        if (col > 0 and !visited[cell - 1]) { next_cells[count] = cell - 1; directions[count] = 3; count += 1; }
        if (count == 0) { depth -= 1; continue; }
        if (cursor >= cells - 1) return -1;
        const choice: usize = @intCast(input[4 + cursor]);
        cursor += 1;
        if (choice >= count) return -1;
        const next = next_cells[choice];
        const direction = directions[choice];
        visited[next] = true;
        walls[cell] &= ~(@as(u8, 1) << @intCast(direction));
        walls[next] &= ~(@as(u8, 1) << @intCast((direction + 2) & 3));
        stack[depth] = next;
        depth += 1;
    }
    if (cursor != cells - 1) return -1;
    for (visited[0..cells]) |seen| if (!seen) return -1;
    if (output_ptr == null or capacity < cells) return -2;
    const output = output_ptr.?[0..cells];
    @memcpy(output, walls[0..cells]);
    return @intCast(cells);
}
