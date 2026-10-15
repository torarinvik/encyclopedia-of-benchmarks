fn putI64Le(output: [*c]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

pub export fn astar_rust_directed_graph(input: [*c]const i64, length: usize, output: [*c]u8, capacity: usize) i64 {
    if (input == null or length < 4) return -1;
    const vertices64 = input[0]; const edge_count64 = input[1];
    if (vertices64 < 1 or vertices64 > 32 or edge_count64 < 0 or edge_count64 > 128) return -1;
    const vertices: usize = @intCast(vertices64); const edge_count: usize = @intCast(edge_count64);
    if (length != 4 + vertices + 3 * edge_count) return -1;
    const start64 = input[2]; const goal64 = input[3];
    if (start64 < 0 or start64 >= vertices64 or goal64 < 0 or goal64 >= vertices64) return -1;
    const start: usize = @intCast(start64); const goal: usize = @intCast(goal64);
    for (0..vertices) |v| if (input[4 + v] < 0 or input[4 + v] > 1_000_000) return -1;
    if (input[4 + goal] != 0) return -1;
    const edge_base = 4 + vertices;
    for (0..edge_count) |e| {
        const from = input[edge_base + 3 * e]; const to = input[edge_base + 3 * e + 1]; const weight = input[edge_base + 3 * e + 2];
        if (from < 0 or from >= vertices64 or to < 0 or to >= vertices64 or weight < 0 or weight > 1_000_000 or input[4 + @as(usize, @intCast(from))] > weight + input[4 + @as(usize, @intCast(to))]) return -1;
    }
    var distance = [_]i64{std.math.maxInt(i64)} ** 32;
    var parent = [_]i64{-1} ** 32;
    var closed = [_]bool{false} ** 32;
    distance[start] = 0;
    for (0..vertices) |_| {
        var current: ?usize = null;
        for (0..vertices) |v| {
            if (closed[v] or distance[v] == std.math.maxInt(i64)) continue;
            if (current) |old| {
                const f = distance[v] + input[4 + v];
                const old_f = distance[old] + input[4 + old];
                if (f < old_f or (f == old_f and (distance[v] < distance[old] or (distance[v] == distance[old] and v < old)))) current = v;
            } else current = v;
        }
        const selected = current orelse break;
        if (selected == goal) break;
        closed[selected] = true;
        for (0..edge_count) |e| {
            const from = input[edge_base + 3 * e]; if (from != @as(i64, @intCast(selected))) continue;
            const next: usize = @intCast(input[edge_base + 3 * e + 1]);
            const candidate = distance[selected] + input[edge_base + 3 * e + 2];
            if (!closed[next] and candidate < distance[next]) { distance[next] = candidate; parent[next] = @intCast(selected); }
        }
    }
    if (distance[goal] == std.math.maxInt(i64)) return 0;
    var reversed = [_]i64{0} ** 32; var path_len: usize = 0; var current: i64 = goal64;
    while (path_len < vertices) {
        reversed[path_len] = current; path_len += 1;
        if (current == start64) break;
        current = parent[@intCast(current)]; if (current < 0) return -1;
    }
    if (reversed[path_len - 1] != start64) return -1;
    const required = 8 * (path_len + 2);
    if (output == null or capacity < required) return -2;
    putI64Le(output, 0, distance[goal]); putI64Le(output, 8, @intCast(path_len));
    for (0..path_len) |i| putI64Le(output, 16 + i * 8, reversed[path_len - 1 - i]);
    return @intCast(required);
}
