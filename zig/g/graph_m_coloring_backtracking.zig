const max_vertices: usize = 12;

fn assignColors(input: [*c]const i64, count: usize, maxColors: usize,
    vertex: usize, colors: []i64) bool {
    if (vertex == count) return true;
    for (0..maxColors) |color| {
        var safe = true;
        for (0..count) |neighbor| {
            if (input[2 + vertex * count + neighbor] == 1 and colors[neighbor] == @as(i64, @intCast(color))) {
                safe = false;
                break;
            }
        }
        if (!safe) continue;
        colors[vertex] = @intCast(color);
        if (assignColors(input, count, maxColors, vertex + 1, colors)) return true;
        colors[vertex] = -1;
    }
    return false;
}

fn putI64(output: [*c]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(byte * 8));
}

pub export fn graph_m_coloring_backtracking(input: [*c]const i64, length: usize,
    output: [*c]u8, capacity: usize) i64 {
    if (input == null or length < 2) return -1;
    const n_value = input[0];
    const max_colors_value = input[1];
    if (n_value < 0 or n_value > 12 or max_colors_value < 0 or max_colors_value > 12) return -1;
    const n: usize = @intCast(n_value);
    const max_colors: usize = @intCast(max_colors_value);
    if (length != 2 + n * n) return -1;
    for (0..n) |row| {
        if (input[2 + row * n + row] != 0) return -1;
        for (0..n) |column| {
            const cell = input[2 + row * n + column];
            if ((cell != 0 and cell != 1) or cell != input[2 + column * n + row]) return -1;
        }
    }
    var colors: [max_vertices]i64 = @splat(-1);
    if (!assignColors(input, n, max_colors, 0, &colors)) return 0;
    const required = n * 8;
    if (required == 0) return 0;
    if (output == null or capacity < required) return -2;
    for (0..n) |vertex| putI64(output, vertex * 8, colors[vertex]);
    return @intCast(required);
}
