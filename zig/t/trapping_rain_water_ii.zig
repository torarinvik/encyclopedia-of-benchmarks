const MAX_ROWS: usize = 8;
const MAX_COLS: usize = 8;
const MAX_CELLS: usize = 64;
const MAX_INPUT: usize = 66;

const Entry = struct { level: i64, cell: usize };
fn less(a: Entry, b: Entry) bool { return a.level < b.level or (a.level == b.level and a.cell < b.cell); }
fn push(heap: *[MAX_CELLS]Entry, size: *usize, item: Entry) void {
    var position = size.*;
    size.* += 1;
    while (position > 0) {
        const parent = (position - 1) / 2;
        if (!less(item, heap.*[parent])) break;
        heap.*[position] = heap.*[parent];
        position = parent;
    }
    heap.*[position] = item;
}
fn pop(heap: *[MAX_CELLS]Entry, size: *usize) Entry {
    const minimum = heap.*[0];
    size.* -= 1;
    if (size.* > 0) {
        const last = heap.*[size.*];
        var position: usize = 0;
        while (2 * position + 1 < size.*) {
            var child = 2 * position + 1;
            if (child + 1 < size.* and less(heap.*[child + 1], heap.*[child])) child += 1;
            if (!less(heap.*[child], last)) break;
            heap.*[position] = heap.*[child];
            position = child;
        }
        heap.*[position] = last;
    }
    return minimum;
}

export fn trapping_rain_water_ii(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length < 2 or length > MAX_INPUT) return -1;
    const input = input_opt.?;
    if (input[0] < 1 or input[0] > 8 or input[1] < 1 or input[1] > 8) return -1;
    const rows: usize = @intCast(input[0]);
    const cols: usize = @intCast(input[1]);
    if (length != 2 + rows * cols) return -1;
    var heights = [_]i64{0} ** MAX_CELLS;
    for (0..rows * cols) |cell| {
        const height = input[2 + cell];
        if (height < 0 or height > 1000) return -1;
        heights[cell] = height;
    }

    var visited = [_]bool{false} ** MAX_CELLS;
    var heap = [_]Entry{.{ .level = 0, .cell = 0 }} ** MAX_CELLS;
    var heap_size: usize = 0;
    for (0..rows) |row| {
        for (0..cols) |col| {
            if (row == 0 or row + 1 == rows or col == 0 or col + 1 == cols) {
                const cell = row * cols + col;
                if (!visited[cell]) {
                    visited[cell] = true;
                    push(&heap, &heap_size, .{ .level = heights[cell], .cell = cell });
                }
            }
        }
    }

    const dr = [_]isize{-1, 1, 0, 0};
    const dc = [_]isize{0, 0, -1, 1};
    const rows_signed: isize = @intCast(rows);
    const cols_signed: isize = @intCast(cols);
    var retained: i64 = 0;
    while (heap_size > 0) {
        const current = pop(&heap, &heap_size);
        const row: isize = @intCast(current.cell / cols);
        const col: isize = @intCast(current.cell % cols);
        for (0..4) |direction| {
            const nr = row + dr[direction];
            const nc = col + dc[direction];
            if (nr < 0 or nr >= rows_signed or nc < 0 or nc >= cols_signed) continue;
            const neighbor: usize = @as(usize, @intCast(nr)) * cols + @as(usize, @intCast(nc));
            if (visited[neighbor]) continue;
            visited[neighbor] = true;
            const height = heights[neighbor];
            if (height < current.level) retained += current.level - height;
            push(&heap, &heap_size, .{ .level = @max(current.level, height), .cell = neighbor });
        }
    }
    return retained;
}
