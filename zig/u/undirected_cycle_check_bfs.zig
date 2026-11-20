export fn undirected_cycle_check_bfs(input_ptr: ?[*]const i64, length: usize) i64 {
    const input = input_ptr orelse return -1;
    if (length < 2 or length > 514 or input[0] < 0 or input[0] > 32 or input[1] < 0 or input[1] > 256) return -1;
    const n: usize = @intCast(input[0]);
    const m: usize = @intCast(input[1]);
    if (length != 2 + 2 * m) return -1;
    var adjacent: [32][32]bool = @splat(@splat(false));
    var visited: [32]bool = @splat(false);
    for (0..m) |i| {
        const a = input[2 + 2 * i];
        const b = input[3 + 2 * i];
        if (a < 0 or b < 0 or a >= @as(i64, @intCast(n)) or b >= @as(i64, @intCast(n))) return -1;
        const u: usize = @intCast(a); const v: usize = @intCast(b);
        if (adjacent[u][v]) return -1;
        adjacent[u][v] = true; adjacent[v][u] = true;
    }
    var queue: [32]usize = undefined;
    var parent: [32]usize = undefined;
    for (0..n) |root| {
        if (visited[root]) continue;
        var head: usize = 0; var tail: usize = 1;
        queue[0] = root; parent[root] = n; visited[root] = true;
        while (head < tail) {
            const u = queue[head]; head += 1;
            for (0..n) |v| {
                if (!adjacent[u][v]) continue;
                if (!visited[v]) {
                    visited[v] = true; parent[v] = u; queue[tail] = v; tail += 1;
                } else if (v != parent[u]) return 1;
            }
        }
    }
    return 0;
}
