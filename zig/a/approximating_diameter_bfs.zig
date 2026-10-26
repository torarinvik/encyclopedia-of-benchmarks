fn put_i64(output: [*c]u8, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |b| output[b] = @truncate(bits >> @intCast(8 * b));
}

export fn approximating_diameter_bfs(input: [*c]const i64, length: usize,
                                     output: [*c]u8, capacity: usize) i64 {
    if (input == null or length < 2 or length > 242) return -1;
    const n0 = input[0]; const m0 = input[1];
    if (n0 < 1 or n0 > 16 or m0 < 0 or m0 > 120 or length != 2 + 2 * @as(usize, @intCast(m0))) return -1;
    const n: usize = @intCast(n0); const m: usize = @intCast(m0);
    var adj = [_]bool{false} ** 256;
    for (0..m) |i| {
        const u0 = input[2 + 2*i]; const v0 = input[3 + 2*i];
        if (u0 < 0 or v0 <= u0 or v0 >= n0) return -1;
        const u: usize = @intCast(u0); const v: usize = @intCast(v0);
        if (adj[u * 16 + v]) return -1;
        adj[u * 16 + v] = true; adj[v * 16 + u] = true;
    }
    var dist = [_]i64{-1} ** 16; var queue = [_]usize{0} ** 16;
    dist[0] = 0; queue[0] = 0; var head: usize = 0; var tail: usize = 1;
    while (head < tail) {
        const u = queue[head]; head += 1;
        for (0..n) |v| {
            if (adj[u * 16 + v] and dist[v] < 0) {
                dist[v] = dist[u] + 1; queue[tail] = v; tail += 1;
            }
        }
    }
    if (tail != n) return -1;
    var estimate: i64 = 0;
    for (0..n) |i| { if (dist[i] > estimate) estimate = dist[i]; }
    if (output == null or capacity < 8) return -2;
    put_i64(output, estimate); return 8;
}
