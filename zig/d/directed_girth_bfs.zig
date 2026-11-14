export fn directed_girth_bfs(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length < 2 or length > 131) return -1;
    const input = input_opt.?;
    if (input[0] < 1 or input[0] > 16 or input[1] < 0 or input[1] > 64) return -1;
    const n: usize = @intCast(input[0]);
    const m: usize = @intCast(input[1]);
    if (length != 2 + 2*m) return -1;
    var outgoing: [16]u32 = @splat(0);
    for (0..m) |i| {
        const u = input[2+2*i];
        const v = input[3+2*i];
        if (u < 0 or v < 0 or u >= input[0] or v >= input[0]) return -1;
        outgoing[@intCast(u)] |= @as(u32, 1) << @intCast(v);
    }
    var best: i64 = 17;
    for (0..n) |start| {
        var distance: [16]i64 = @splat(-1);
        var queue: [16]usize = @splat(0);
        var head: usize = 0;
        var tail: usize = 1;
        distance[start] = 0; queue[0] = start;
        while (head < tail) {
            const u = queue[head]; head += 1;
            for (0..n) |v| {
                if (outgoing[u] & (@as(u32, 1) << @intCast(v)) == 0) continue;
                if (v == start) {
                    if (distance[u] + 1 < best) best = distance[u] + 1;
                } else if (distance[v] < 0) {
                    distance[v] = distance[u] + 1; queue[tail] = v; tail += 1;
                }
            }
        }
    }
    return if (best == 17) 0 else best;
}
