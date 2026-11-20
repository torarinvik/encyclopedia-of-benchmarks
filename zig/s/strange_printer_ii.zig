const MAX_ROWS: usize = 6;
const MAX_COLUMNS: usize = 6;
const MAX_COLORS: usize = 6;
const COLOR_SIDE: usize = 7;
const MAX_PARSEABLE_LENGTH: usize = 39;

fn solve(input: []const i64) i64 {
    if (input.len < 2 or input.len > MAX_PARSEABLE_LENGTH) return -1;
    const rows_raw = input[0];
    const columns_raw = input[1];
    if (rows_raw < 1 or rows_raw > MAX_ROWS or columns_raw < 1 or columns_raw > MAX_COLUMNS) return -1;
    const rows: usize = @intCast(rows_raw);
    const columns: usize = @intCast(columns_raw);
    if (input.len != 2 + rows * columns) return -1;
    for (input[2..]) |color| {
        if (color < 1 or color > MAX_COLORS) return -1;
    }

    var first_row: [COLOR_SIDE]i64 = @splat(rows_raw);
    var last_row: [COLOR_SIDE]i64 = @splat(-1);
    var first_column: [COLOR_SIDE]i64 = @splat(columns_raw);
    var last_column: [COLOR_SIDE]i64 = @splat(-1);
    var outgoing: [COLOR_SIDE]i64 = @splat(0);
    var indegree: [COLOR_SIDE]i64 = @splat(0);
    var queue: [COLOR_SIDE]i64 = @splat(0);
    for (0..rows) |row| {
        for (0..columns) |column| {
            const color: usize = @intCast(input[2 + row * columns + column]);
            first_row[color] = @min(first_row[color], @as(i64, @intCast(row)));
            last_row[color] = @max(last_row[color], @as(i64, @intCast(row)));
            first_column[color] = @min(first_column[color], @as(i64, @intCast(column)));
            last_column[color] = @max(last_column[color], @as(i64, @intCast(column)));
        }
    }

    var present_count: i64 = 0;
    for (1..MAX_COLORS + 1) |color| {
        if (last_row[color] < 0) continue;
        present_count += 1;
        const top: usize = @intCast(first_row[color]);
        const bottom: usize = @intCast(last_row[color]);
        const left: usize = @intCast(first_column[color]);
        const right: usize = @intCast(last_column[color]);
        for (top..bottom + 1) |row| {
            for (left..right + 1) |column| {
                const covered: usize = @intCast(input[2 + row * columns + column]);
                const bit: i64 = @as(i64, 1) << @intCast(covered);
                if (covered != color and (outgoing[color] & bit) == 0) {
                    outgoing[color] |= bit;
                    indegree[covered] += 1;
                }
            }
        }
    }
    var head: usize = 0;
    var tail: usize = 0;
    for (1..MAX_COLORS + 1) |color| {
        if (last_row[color] >= 0 and indegree[color] == 0) {
            queue[tail] = @intCast(color);
            tail += 1;
        }
    }
    var processed: i64 = 0;
    while (head < tail) {
        const color: usize = @intCast(queue[head]);
        head += 1;
        processed += 1;
        for (1..MAX_COLORS + 1) |later| {
            const bit: i64 = @as(i64, 1) << @intCast(later);
            if ((outgoing[color] & bit) != 0) {
                indegree[later] -= 1;
                if (indegree[later] == 0) {
                    queue[tail] = @intCast(later);
                    tail += 1;
                }
            }
        }
    }
    return if (processed == present_count) 1 else 0;
}

pub export fn strange_printer_ii(input: [*c]const i64, length: usize) i64 {
    if (input == null or length < 2 or length > MAX_PARSEABLE_LENGTH) return -1;
    return solve(input[0..length]);
}
