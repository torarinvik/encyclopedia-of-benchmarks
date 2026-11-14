export fn incremental_minimum_spanning_forest(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 2 or length > 98) return -1;
    const input = input_opt.?;
    if (input[0] < 1 or input[0] > 16 or input[1] < 1 or input[1] > 32) return -1;
    const m: usize = @intCast(input[1]);
    if (length != 2 + 3 * m) return -1;
    for (0..m) |i| {
        const u = input[2+3*i]; const v = input[3+3*i]; const w = input[4+3*i];
        if (u < 0 or u >= input[0] or v < 0 or v >= input[0] or w < 1 or w > 1000000) return -1;
        for (0..i) |j| if (input[4+3*j] == w) { return -1; };
    }
    var active: [32]bool = @splat(false);
    var answers: [32]i64 = @splat(0);
    for (0..m) |edge| {
        const start: usize = @intCast(input[2+3*edge]);
        const target: usize = @intCast(input[3+3*edge]);
        if (start == target) { answers[edge] = @intCast(edge); continue; }
        var parent: [16]i32 = @splat(-1);
        var parent_edge: [16]usize = @splat(0);
        var queue: [16]usize = @splat(0);
        var head: usize = 0; var tail: usize = 1;
        queue[0] = start; parent[start] = @intCast(start);
        while (head < tail) {
            const vertex = queue[head]; head += 1;
            for (0..edge) |i| {
                if (!active[i]) continue;
                const u: usize = @intCast(input[2+3*i]); const v: usize = @intCast(input[3+3*i]);
                const neighbor: ?usize = if (u == vertex) v else if (v == vertex) u else null;
                if (neighbor) |next| {
                    if (parent[next] < 0) {
                        parent[next] = @intCast(vertex); parent_edge[next] = i;
                        queue[tail] = next; tail += 1;
                    }
                }
            }
        }
        if (parent[target] < 0) { active[edge] = true; answers[edge] = -1; continue; }
        var node = target; var heaviest = parent_edge[node];
        while (node != start) {
            const i = parent_edge[node];
            if (input[4+3*i] > input[4+3*heaviest]) heaviest = i;
            node = @intCast(parent[node]);
        }
        if (input[4+3*edge] < input[4+3*heaviest]) {
            active[heaviest] = false; active[edge] = true; answers[edge] = @intCast(heaviest);
        } else { answers[edge] = @intCast(edge); }
    }
    const bytes = 8 * m;
    if (output_opt == null or capacity < bytes) return -2;
    const output = output_opt.?;
    for (0..m) |i| {
        const bits: u64 = @bitCast(answers[i]);
        for (0..8) |b| output[8*i+b] = @truncate(bits >> @as(u6, @intCast(8*b)));
    }
    return @intCast(bytes);
}
