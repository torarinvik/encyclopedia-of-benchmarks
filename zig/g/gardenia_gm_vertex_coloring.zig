// Clean-room bounded GARDENIA Gebremedhin-Manne coloring profile.
const MAX_N = 16;
const MAX_M = 64;
const MAX_INPUT = 130;
const MAX_COLOR = 128;

fn putI64Le(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn gardenia_gm_vertex_coloring(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 2 or length > MAX_INPUT) return -1;
    const input = input_opt.?;
    const n64, const m64 = .{ input[0], input[1] };
    if (n64 < 1 or n64 > MAX_N or m64 < 0 or m64 > MAX_M or length != 2 + 2 * @as(usize, @intCast(m64))) return -1;
    const n: usize = @intCast(n64);
    const m: usize = @intCast(m64);
    var adjacent: [MAX_N * MAX_N]u8 = @splat(0);
    for (0..m) |e| {
        const u64 = input[2 + 2 * e];
        const v64 = input[3 + 2 * e];
        if (u64 < 0 or v64 <= u64 or v64 >= n64) return -1;
        const u: usize = @intCast(u64);
        const v: usize = @intCast(v64);
        if (adjacent[u * MAX_N + v] != 0) return -1;
        adjacent[u * MAX_N + v] = 1;
        adjacent[v * MAX_N + u] = 1;
    }
    const output_bytes = 8 * n;
    if (output_opt == null or capacity < output_bytes) return -2;
    var colors: [MAX_N]usize = @splat(0);
    var prior: [MAX_N]usize = @splat(0);
    var pending: [MAX_N]usize = @splat(0);
    var next_pending: [MAX_N]usize = @splat(0);
    var pending_count = n;
    for (0..n) |u| { colors[u] = MAX_COLOR; pending[u] = u; }
    var rounds: usize = 0;
    while (pending_count > 0) {
        rounds += 1;
        if (rounds > n + 1) return -1;
        for (0..n) |u| prior[u] = colors[u];
        for (0..pending_count) |item| {
            const u = pending[item];
            var forbidden: [MAX_N]bool = @splat(false);
            for (0..n) |v| {
                if (adjacent[u * MAX_N + v] != 0 and prior[v] != MAX_COLOR) forbidden[prior[v]] = true;
            }
            var color: usize = 0;
            while (color < MAX_COLOR and forbidden[color]) : (color += 1) {}
            if (color >= MAX_COLOR) return -1;
            colors[u] = color;
        }
        var next_count: usize = 0;
        for (0..pending_count) |item| {
            const u = pending[item];
            var conflict = false;
            for (u + 1..n) |v| {
                if (adjacent[u * MAX_N + v] != 0 and colors[u] == colors[v]) { conflict = true; break; }
            }
            if (conflict) {
                colors[u] = MAX_COLOR;
                next_pending[next_count] = u;
                next_count += 1;
            }
        }
        pending_count = next_count;
        for (0..pending_count) |item| pending[item] = next_pending[item];
    }
    const output = output_opt.?;
    for (0..n) |u| putI64Le(output, 8 * u, @intCast(colors[u]));
    return @intCast(output_bytes);
}
