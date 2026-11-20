export fn undirected_eulerian_trail_hierholzer(input: ?[*]const i64, length: usize, output: ?[*]u8, capacity: usize) i64 {
    if (input == null or length < 2 or length > 67) return -1;
    const v = input.?;
    if (v[0] < 1 or v[0] > 16 or v[1] < 0 or v[1] > 32) return -1;
    const n: usize = @intCast(v[0]); const m: usize = @intCast(v[1]);
    if (length != 2 + 2 * m) return -1;
    var endpoints: [32][2]usize = undefined;
    var adjacency: [16][64]usize = undefined;
    var degree: [16]usize = @splat(0); var cursor: [16]usize = @splat(0);
    for (0..m) |e| {
        const u0 = v[2 + 2 * e]; const v0 = v[3 + 2 * e];
        if (u0 < 0 or v0 < 0 or u0 >= @as(i64, @intCast(n)) or v0 >= @as(i64, @intCast(n))) return -1;
        const u: usize = @intCast(u0); const w: usize = @intCast(v0);
        endpoints[e] = .{ u, w }; adjacency[u][degree[u]] = e; degree[u] += 1;
        adjacency[w][degree[w]] = e; degree[w] += 1;
    }
    var odd: usize = 0; var start: usize = 0;
    for (0..n) |x| {
        if (degree[x] % 2 != 0) { if (odd == 0) start = x; odd += 1; }
    }
    if (odd != 0 and odd != 2) return 0;
    if (odd == 0 and m != 0) { while (degree[start] == 0) { start += 1; } }
    var used: [32]bool = @splat(false); var stack: [33]usize = undefined; var reverse: [33]usize = undefined;
    var top: usize = 1; var count: usize = 0; stack[0] = start;
    while (top != 0) {
        const x = stack[top - 1];
        while (cursor[x] < degree[x] and used[adjacency[x][cursor[x]]]) cursor[x] += 1;
        if (cursor[x] == degree[x]) { top -= 1; reverse[count] = stack[top]; count += 1; }
        else { const e = adjacency[x][cursor[x]]; cursor[x] += 1; used[e] = true;
            stack[top] = if (endpoints[e][0] == x) endpoints[e][1] else endpoints[e][0]; top += 1; }
    }
    if (count != m + 1) return 0;
    const bytes = count * 8;
    if (output == null or capacity < bytes) return -2;
    for (0..count) |i| {
        const value: u64 = @intCast(reverse[count - 1 - i]);
        for (0..8) |b| output.?[8 * i + b] = @truncate(value >> @intCast(8 * b));
    }
    return @intCast(bytes);
}
