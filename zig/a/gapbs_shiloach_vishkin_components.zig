const MAX_N: usize = 16;

fn compressComponents(n: usize, component: *[MAX_N]usize) void {
    for (0..n) |node| {
        while (component[node] != component[component[node]]) {
            component[node] = component[component[node]];
        }
    }
}

fn storeI64LE(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @as(u6, @intCast(8 * byte)));
}

export fn gapbs_shiloach_vishkin_components(input: ?[*]const i64, length: usize,
    output: ?[*]u8, capacity: usize) i64 {
    const values = input orelse return -1;
    if (length < 2 or length > 130) return -1;
    const n64 = values[0];
    const m64 = values[1];
    if (n64 < 1 or n64 > 16 or m64 < 0 or m64 > 64) return -1;
    const n: usize = @intCast(n64);
    const m: usize = @intCast(m64);
    if (length != 2 + 2 * m) return -1;
    var adjacency = [_]u8{0} ** (MAX_N * MAX_N);
    for (0..m) |edge| {
        const pos = 2 + 2 * edge;
        const u = values[pos];
        const v = values[pos + 1];
        if (u < 0 or v <= u or v >= n64) return -1;
        const ui: usize = @intCast(u);
        const vi: usize = @intCast(v);
        if (adjacency[ui * MAX_N + vi] != 0) return -1;
        adjacency[ui * MAX_N + vi] = 1;
        adjacency[vi * MAX_N + ui] = 1;
    }
    const output_bytes = 8 * n;
    const out = output orelse return -2;
    if (capacity < output_bytes) return -2;
    var component = [_]usize{0} ** MAX_N;
    for (0..n) |node| component[node] = node;
    var changed = true;
    var rounds: usize = 0;
    const round_limit = n * n + 1;
    while (changed and rounds < round_limit) {
        changed = false;
        for (0..n) |u| {
            for (0..n) |v| {
                if (adjacency[u * MAX_N + v] == 0) continue;
                const component_u = component[u];
                const component_v = component[v];
                if (component_u == component_v) continue;
                const high = @max(component_u, component_v);
                const low = @min(component_u, component_v);
                if (component[high] == high) { changed = true; component[high] = low; }
            }
        }
        compressComponents(n, &component);
        rounds += 1;
    }
    if (changed) return -1;
    for (0..n) |node| storeI64LE(out, 8 * node, @intCast(component[node]));
    return @intCast(output_bytes);
}
