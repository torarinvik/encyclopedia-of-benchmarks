/// Return the largest four-connected component of cells equal to one.
export fn max_area_of_island(input: [*c]const i64, length: usize) i64 {
    const max_rows: usize = 16;
    const max_columns: usize = 16;
    const max_cells: usize = max_rows * max_columns;
    if (input == null or length < 2 or input[0] < 0 or input[0] > 16 or
        input[1] < 0 or input[1] > 16) return -1;
    const rows: usize = @intCast(input[0]);
    const columns: usize = @intCast(input[1]);
    const cells = rows * columns;
    if (length != cells + 2) return -1;
    for (0..cells) |i| {
        if (input[2 + i] != 0 and input[2 + i] != 1) return -1;
    }

    var visited: [max_cells]bool = @splat(false);
    var stack: [max_cells]usize = undefined;
    var maximum_area: usize = 0;
    for (0..cells) |start| {
        if (input[2 + start] == 0 or visited[start]) continue;
        var top: usize = 0;
        var area: usize = 0;
        visited[start] = true;
        stack[top] = start;
        top += 1;
        while (top > 0) {
            top -= 1;
            const current = stack[top];
            area += 1;
            const row = current / columns;
            const column = current % columns;
            if (row > 0) {
                const neighbor = current - columns;
                if (!visited[neighbor] and input[2 + neighbor] == 1) {
                    visited[neighbor] = true;
                    stack[top] = neighbor;
                    top += 1;
                }
            }
            if (row + 1 < rows) {
                const neighbor = current + columns;
                if (!visited[neighbor] and input[2 + neighbor] == 1) {
                    visited[neighbor] = true;
                    stack[top] = neighbor;
                    top += 1;
                }
            }
            if (column > 0) {
                const neighbor = current - 1;
                if (!visited[neighbor] and input[2 + neighbor] == 1) {
                    visited[neighbor] = true;
                    stack[top] = neighbor;
                    top += 1;
                }
            }
            if (column + 1 < columns) {
                const neighbor = current + 1;
                if (!visited[neighbor] and input[2 + neighbor] == 1) {
                    visited[neighbor] = true;
                    stack[top] = neighbor;
                    top += 1;
                }
            }
        }
        maximum_area = @max(maximum_area, area);
    }
    return @intCast(maximum_area);
}
