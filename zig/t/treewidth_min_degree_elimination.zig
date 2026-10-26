const N: usize = 16;
const MAX_EDGES: usize = 120;
const MAX_INPUT: usize = 242;
const MAX_OUTPUT: usize = 2064;

fn putI64(out: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| out[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn treewidth_min_degree_elimination(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 2 or length > MAX_INPUT) return -1;
    const input = input_opt.?;
    const n64 = input[0];
    const m64 = input[1];
    if (n64 < 1 or n64 > 16 or m64 < 0 or m64 > 120) return -1;
    const n: usize = @intCast(n64);
    const m: usize = @intCast(m64);
    if (m > n * (n - 1) / 2 or length != 2 + 2 * m) return -1;
    var adjacent: [N][N]bool = @splat(@splat(false));
    for (0..m) |edge| {
        const a64 = input[2 + 2 * edge];
        const b64 = input[3 + 2 * edge];
        if (a64 < 0 or b64 < 0 or a64 >= n64 or b64 >= n64 or a64 >= b64) return -1;
        const a: usize = @intCast(a64);
        const b: usize = @intCast(b64);
        if (adjacent[a][b]) return -1;
        adjacent[a][b] = true;
        adjacent[b][a] = true;
    }
    var active: [N]bool = @splat(false);
    for (0..n) |i| active[i] = true;
    var order: [N]i64 = @splat(0);
    var fill_u: [MAX_EDGES]i64 = @splat(0);
    var fill_v: [MAX_EDGES]i64 = @splat(0);
    var width: usize = 0;
    var fill_count: usize = 0;
    for (0..n) |step| {
        var chosen: usize = 0;
        var chosen_degree: usize = N + 1;
        for (0..n) |vertex| {
            if (!active[vertex]) continue;
            var degree: usize = 0;
            for (0..n) |other| if (active[other] and adjacent[vertex][other]) { degree += 1; };
            if (degree < chosen_degree) { chosen = vertex; chosen_degree = degree; }
        }
        order[step] = @intCast(chosen);
        width = @max(width, chosen_degree);
        var neighbors: [N]usize = @splat(0);
        var neighbor_count: usize = 0;
        for (0..n) |other| {
            if (active[other] and adjacent[chosen][other]) {
                neighbors[neighbor_count] = other;
                neighbor_count += 1;
            }
        }
        for (0..neighbor_count) |i| {
            for (i + 1..neighbor_count) |j| {
                const a = neighbors[i];
                const b = neighbors[j];
                if (!adjacent[a][b]) {
                    adjacent[a][b] = true;
                    adjacent[b][a] = true;
                    fill_u[fill_count] = @intCast(a);
                    fill_v[fill_count] = @intCast(b);
                    fill_count += 1;
                }
            }
        }
        active[chosen] = false;
    }
    const bytes = 8 * (n + 2 + 2 * fill_count);
    if (output_opt == null or capacity < bytes or bytes > MAX_OUTPUT) return -2;
    var staged: [MAX_OUTPUT]u8 = @splat(0);
    putI64(&staged, 0, @intCast(width));
    for (0..n) |i| putI64(&staged, 8 * (i + 1), order[i]);
    putI64(&staged, 8 * (n + 1), @intCast(fill_count));
    for (0..fill_count) |i| {
        putI64(&staged, 8 * (n + 2 + 2 * i), fill_u[i]);
        putI64(&staged, 8 * (n + 3 + 2 * i), fill_v[i]);
    }
    @memcpy(output_opt.?[0..bytes], staged[0..bytes]);
    return @intCast(bytes);
}
