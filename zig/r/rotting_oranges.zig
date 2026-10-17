const MAX_CELLS: usize = 256;
const MAX_INPUT_LENGTH: usize = 259;
const INVALID_RESULT: i64 = -9223372036854775808;

export fn rotting_oranges(input: [*c]const i64, length: usize) i64 {
    if (input == null) return if (length == 0) 0 else INVALID_RESULT;
    if (length == 0) return 0;
    if (length < 2 or length > MAX_INPUT_LENGTH) return INVALID_RESULT;
    if (input[0] == 0) return if (input[1] == 0 and length == 2) 0 else INVALID_RESULT;
    if (input[0] < 1 or input[0] > 16 or input[1] < 0 or input[1] > 16) return INVALID_RESULT;

    const rows: usize = @intCast(input[0]);
    const columns: usize = @intCast(input[1]);
    const cell_count = rows * columns;
    if (length != 2 + cell_count) return INVALID_RESULT;

    var cells: [MAX_CELLS]u8 = @splat(0);
    var queue: [MAX_CELLS]usize = undefined;
    var distance: [MAX_CELLS]u16 = @splat(0);
    var head: usize = 0;
    var tail: usize = 0;
    var fresh: usize = 0;
    var rotted: usize = 0;
    for (0..cell_count) |index| {
        const value = input[2 + index];
        if (value < 0 or value > 2) return INVALID_RESULT;
        cells[index] = @intCast(value);
        if (value == 1) fresh += 1;
        if (value == 2) {
            queue[tail] = index;
            tail += 1;
        }
    }
    if (columns == 0 or fresh == 0) return 0;

    var minutes: u16 = 0;
    while (head < tail) {
        const index = queue[head];
        head += 1;
        const row = index / columns;
        const column = index % columns;
        const next_distance = distance[index] + 1;
        var neighbors: [4]usize = undefined;
        var neighbor_count: usize = 0;
        if (row > 0) {
            neighbors[neighbor_count] = index - columns;
            neighbor_count += 1;
        }
        if (column + 1 < columns) {
            neighbors[neighbor_count] = index + 1;
            neighbor_count += 1;
        }
        if (row + 1 < rows) {
            neighbors[neighbor_count] = index + columns;
            neighbor_count += 1;
        }
        if (column > 0) {
            neighbors[neighbor_count] = index - 1;
            neighbor_count += 1;
        }
        for (0..neighbor_count) |offset| {
            const next = neighbors[offset];
            if (cells[next] != 1) continue;
            cells[next] = 2;
            distance[next] = next_distance;
            minutes = @max(minutes, next_distance);
            rotted += 1;
            queue[tail] = next;
            tail += 1;
        }
    }
    return if (rotted == fresh) @intCast(minutes) else -1;
}
