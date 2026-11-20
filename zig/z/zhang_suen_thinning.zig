/// Zhang-Suen binary image thinning with simultaneous phase deletions.
const MAX_ROWS: i64 = 32;
const MAX_COLUMNS: i64 = 32;
const MAX_CELLS: usize = 1024;
const MAX_PARSEABLE_INPUT_LENGTH: usize = 1027;

fn thinPhase(image: []u8, marked: []u8, rows: usize, columns: usize,
    second_phase: bool) bool {
    const cells = rows * columns;
    @memset(marked[0..cells], 0);
    var changed = false;
    var row: usize = 1;
    while (row + 1 < rows) : (row += 1) {
        var column: usize = 1;
        while (column + 1 < columns) : (column += 1) {
            const index = row * columns + column;
            if (image[index] == 0) continue;
            const p2 = image[index - columns];
            const p3 = image[index - columns + 1];
            const p4 = image[index + 1];
            const p5 = image[index + columns + 1];
            const p6 = image[index + columns];
            const p7 = image[index + columns - 1];
            const p8 = image[index - 1];
            const p9 = image[index - columns - 1];
            const ring = [_]u8{ p2, p3, p4, p5, p6, p7, p8, p9, p2 };
            var black_neighbors: usize = 0;
            var transitions: usize = 0;
            for (0..8) |neighbor| {
                black_neighbors += ring[neighbor];
                if (ring[neighbor] == 0 and ring[neighbor + 1] == 1) transitions += 1;
            }
            if (black_neighbors < 2 or black_neighbors > 6 or transitions != 1) continue;
            const blocked = if (second_phase)
                ((p2 != 0 and p4 != 0 and p8 != 0) or (p2 != 0 and p6 != 0 and p8 != 0))
            else
                ((p2 != 0 and p4 != 0 and p6 != 0) or (p4 != 0 and p6 != 0 and p8 != 0));
            if (blocked) continue;
            marked[index] = 1;
            changed = true;
        }
    }
    if (changed) {
        for (0..cells) |index| {
            if (marked[index] != 0) image[index] = 0;
        }
    }
    return changed;
}

export fn zhang_suen_thinning(input: [*c]const i64, length: usize,
    output: [*c]u8, output_capacity: usize) i64 {
    if (input == null or length < 3 or length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    const rows_value = input[0];
    const columns_value = input[1];
    if (rows_value < 1 or rows_value > MAX_ROWS or
        columns_value < 1 or columns_value > MAX_COLUMNS) return -1;
    const rows: usize = @intCast(rows_value);
    const columns: usize = @intCast(columns_value);
    const cells = rows * columns;
    if (length != 2 + cells) return -1;
    for (0..cells) |index| {
        if (input[index + 2] != 0 and input[index + 2] != 1) return -1;
    }
    if (output == null or output_capacity < cells) return -2;

    var image = [_]u8{0} ** MAX_CELLS;
    var marked = [_]u8{0} ** MAX_CELLS;
    for (0..cells) |index| image[index] = @intCast(input[index + 2]);
    while (true) {
        const first_changed = thinPhase(image[0..cells], marked[0..cells], rows, columns, false);
        const second_changed = thinPhase(image[0..cells], marked[0..cells], rows, columns, true);
        if (!first_changed and !second_changed) break;
    }
    for (0..cells) |index| output[index] = image[index];
    return @intCast(cells);
}
