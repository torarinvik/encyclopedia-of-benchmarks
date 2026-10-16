const max_n: usize = 7;

fn emitRow(items: *const [max_n]u8, n: usize, output: []u8, rows: *usize) void {
    const offset = rows.* * n;
    for (0..n) |index| output[offset + index] = items[index];
    rows.* += 1;
}

fn generate(items: *[max_n]u8, n: usize, size: usize,
            output: []u8, rows: *usize) void {
    if (size == 1) {
        emitRow(items, n, output, rows);
        return;
    }
    for (0..size) |index| {
        generate(items, n, size - 1, output, rows);
        const swap_index = if (size % 2 == 1) index else 0;
        const temporary = items[swap_index];
        items[swap_index] = items[size - 1];
        items[size - 1] = temporary;
    }
}

export fn heaps(values: [*c]const i64, length: usize,
                output: [*c]u8, capacity: usize) i64 {
    if (values == null or length != 1) return -1;
    const n64 = values[0];
    if (n64 < 0 or n64 > max_n) return -1;
    const n: usize = @intCast(n64);
    if (n == 0) return 0;
    var row_count: usize = 1;
    for (2..n + 1) |factor| row_count *= factor;
    const required = row_count * n;
    if (output == null or capacity < required) return -2;
    var items: [max_n]u8 = @splat(0);
    for (0..n) |index| items[index] = '1' + @as(u8, @intCast(index));
    var rows: usize = 0;
    generate(&items, n, n, output[0..required], &rows);
    return @intCast(rows);
}
