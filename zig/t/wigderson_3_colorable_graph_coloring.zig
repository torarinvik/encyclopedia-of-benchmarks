const MAX_VERTICES: usize = 32;
const MAX_EDGES: usize = 128;
const MAX_INPUT: usize = 2 + 2 * MAX_EDGES;

export fn wigderson_3_colorable_graph_coloring(input_opt: ?[*]const i64,
    length: usize, output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 2 or length > MAX_INPUT + 1) return -1;
    const input = input_opt.?;
    if (input[0] < 0 or input[0] > @as(i64, @intCast(MAX_VERTICES))
        or input[1] < 0 or input[1] > @as(i64, @intCast(MAX_EDGES))) return -1;
    const n: usize = @intCast(input[0]);
    const m: usize = @intCast(input[1]);
    if (length != 2 + 2 * m) return -1;

    var adjacent = [_]bool{false} ** (MAX_VERTICES * MAX_VERTICES);
    for (0..m) |edge| {
        const raw_u = input[2 + 2 * edge];
        const raw_v = input[3 + 2 * edge];
        if (raw_u < 0 or raw_v <= raw_u or raw_v >= @as(i64, @intCast(n))) return -1;
        const u: usize = @intCast(raw_u);
        const v: usize = @intCast(raw_v);
        const uv = u * MAX_VERTICES + v;
        const vu = v * MAX_VERTICES + u;
        if (adjacent[uv]) return -1;
        adjacent[uv] = true;
        adjacent[vu] = true;
    }

    var active = [_]bool{false} ** MAX_VERTICES;
    var color = [_]u8{0} ** MAX_VERTICES;
    for (0..n) |v| active[v] = true;
    var threshold: usize = 0;
    while ((threshold + 1) * (threshold + 1) <= n) threshold += 1;
    var next_color: usize = 1;

    while (true) {
        var chosen = n;
        var maximum_degree: usize = 0;
        for (0..n) |v| {
            if (!active[v]) continue;
            var degree: usize = 0;
            for (0..n) |w| if (active[w] and adjacent[v * MAX_VERTICES + w]) { degree += 1; };
            if (chosen == n or degree > maximum_degree) {
                chosen = v;
                maximum_degree = degree;
            }
        }
        if (chosen == n or maximum_degree < threshold) break;

        var in_neighborhood = [_]bool{false} ** MAX_VERTICES;
        var side = [_]i8{-1} ** MAX_VERTICES;
        var queue = [_]usize{0} ** MAX_VERTICES;
        for (0..n) |v| in_neighborhood[v] = active[v] and adjacent[chosen * MAX_VERTICES + v];
        for (0..n) |root| {
            if (!in_neighborhood[root] or side[root] >= 0) continue;
            var head: usize = 0;
            var tail: usize = 0;
            side[root] = 0;
            queue[tail] = root;
            tail += 1;
            while (head < tail) {
                const u = queue[head];
                head += 1;
                for (0..n) |v| {
                    if (!in_neighborhood[v] or !adjacent[u * MAX_VERTICES + v]) continue;
                    if (side[v] < 0) {
                        side[v] = 1 - side[u];
                        queue[tail] = v;
                        tail += 1;
                    } else if (side[v] == side[u]) return -1;
                }
            }
        }
        for (0..n) |v| if (in_neighborhood[v]) { color[v] = @intCast(next_color + @as(usize, @intCast(side[v]))); };
        color[chosen] = @intCast(next_color + 2);
        active[chosen] = false;
        for (0..n) |v| if (adjacent[chosen * MAX_VERTICES + v]) { active[v] = false; };
        next_color += 2;
    }

    for (0..n) |v| {
        if (!active[v]) continue;
        var used = [_]bool{false} ** (MAX_VERTICES + 2);
        for (0..n) |w| if (adjacent[v * MAX_VERTICES + w] and color[w] > 0) {
            used[@as(usize, color[w])] = true;
        };
        var candidate = next_color;
        while (candidate < used.len and used[candidate]) candidate += 1;
        if (candidate >= used.len) return -1;
        color[v] = @intCast(candidate);
    }

    var palette: u8 = 0;
    for (0..n) |v| if (color[v] > palette) { palette = color[v]; };
    const output_bytes = n + 1;
    if (output_opt == null or capacity < output_bytes) return -2;
    const output = output_opt.?;
    output[0] = palette;
    for (0..n) |v| output[v + 1] = color[v];
    return @intCast(output_bytes);
}
