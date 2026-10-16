const max_values: usize = 6;
const bytes_per_value: usize = 8;

fn emitRow(values: *const [max_values]i64, n: usize, output: []u8, rows: *usize) void {
    const row_offset = rows.* * n * bytes_per_value;
    for (0..n) |index| {
        const bits: u64 = @bitCast(values[index]);
        for (0..bytes_per_value) |byte| {
            output[row_offset + index * bytes_per_value + byte] =
                @truncate(bits >> @intCast(8 * byte));
        }
    }
    rows.* += 1;
}

fn generate(values: *[max_values]i64, n: usize, k: usize,
            output: []u8, rows: *usize) void {
    if (k == 1) {
        emitRow(values, n, output, rows);
        return;
    }
    generate(values, n, k - 1, output, rows);
    for (0..k - 1) |index| {
        const swap_index = if (k % 2 == 0) index else 0;
        const temporary = values[swap_index];
        values[swap_index] = values[k - 1];
        values[k - 1] = temporary;
        generate(values, n, k - 1, output, rows);
    }
}

export fn heaps_algorithm(values: [*c]const i64, length: usize,
                          output: [*c]u8, capacity: usize) i64 {
    if (values == null or length < 1 or length > max_values) return -1;
    var row_count: usize = 1;
    for (2..length + 1) |factor| row_count *= factor;
    const required = row_count * length * bytes_per_value;
    if (output == null or capacity < required) return -2;
    var items: [max_values]i64 = @splat(0);
    for (0..length) |index| items[index] = values[index];
    var rows: usize = 0;
    generate(&items, length, length, output[0..required], &rows);
    return @intCast(rows);
}
