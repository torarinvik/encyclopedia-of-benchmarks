const max_length = 15;

fn mgFree(vertex: usize, color: i64, vertices: usize,
          edge_at: [36]i32, colors: [6]i64) bool {
    for (0..vertices) |other| {
        const edge = edge_at[vertex * 6 + other];
        if (edge >= 0 and colors[@intCast(edge)] == color) return false;
    }
    return true;
}

export fn misra_gries_edge_coloring(input: [*c]const i64, length: usize) i64 {
    if (input == null or length < 2 or length > max_length) return -1;
    if (input[0] < 1 or input[0] > 6 or input[1] < 0 or input[1] > 6) return -1;
    const vertices: usize = @intCast(input[0]);
    const edge_count: usize = @intCast(input[1]);
    if (length != 2 + 2 * edge_count) return -1;

    var left: [6]usize = @splat(0);
    var right: [6]usize = @splat(0);
    var degree: [6]usize = @splat(0);
    var edge_at: [36]i32 = @splat(-1);
    for (0..edge_count) |edge| {
        const a = input[2 + 2 * edge];
        const b = input[3 + 2 * edge];
        if (a < 0 or b < 0 or a >= input[0] or b >= input[0] or a == b) return -1;
        const u: usize = @intCast(@min(a, b));
        const v: usize = @intCast(@max(a, b));
        if (edge_at[u * 6 + v] >= 0) return -1;
        left[edge] = u;
        right[edge] = v;
        edge_at[u * 6 + v] = @intCast(edge);
        edge_at[v * 6 + u] = @intCast(edge);
        degree[u] += 1;
        degree[v] += 1;
    }
    var delta: usize = 0;
    for (0..vertices) |vertex| if (degree[vertex] > delta) { delta = degree[vertex]; };
    const palette: usize = if (edge_count == 0) 0 else delta + 1;
    var colors: [6]i64 = @splat(-1);

    for (0..edge_count) |edge| {
        const center = left[edge];
        var fan: [6]usize = @splat(0);
        var fan_count: usize = 1;
        fan[0] = right[edge];
        while (true) {
            const tail = fan[fan_count - 1];
            var extended = false;
            for (0..vertices) |neighbor| {
                const candidate = edge_at[center * 6 + neighbor];
                if (candidate < 0 or colors[@intCast(candidate)] < 0) continue;
                var present = false;
                for (0..fan_count) |i| if (fan[i] == neighbor) { present = true; };
                if (present or !mgFree(tail, colors[@intCast(candidate)], vertices, edge_at, colors)) continue;
                fan[fan_count] = neighbor;
                fan_count += 1;
                extended = true;
                break;
            }
            if (!extended) break;
        }
        var color_c: i64 = 0;
        while (color_c < @as(i64, @intCast(palette)) and !mgFree(center, color_c, vertices, edge_at, colors)) {
            color_c += 1;
        }
        var color_d: i64 = 0;
        while (color_d < @as(i64, @intCast(palette)) and !mgFree(fan[fan_count - 1], color_d, vertices, edge_at, colors)) {
            color_d += 1;
        }
        if (color_c >= @as(i64, @intCast(palette)) or color_d >= @as(i64, @intCast(palette))) return -1;

        var path: [6]usize = @splat(0);
        var path_count: usize = 0;
        var current = center;
        var wanted = color_d;
        var visited: [6]bool = @splat(false);
        visited[current] = true;
        for (0..vertices) |_| {
            var path_edge: i32 = -1;
            var next: usize = 0;
            for (0..vertices) |neighbor| {
                const candidate = edge_at[current * 6 + neighbor];
                if (candidate >= 0 and colors[@intCast(candidate)] == wanted) {
                    path_edge = candidate;
                    next = neighbor;
                    break;
                }
            }
            if (path_edge < 0 or visited[next]) break;
            path[path_count] = @intCast(path_edge);
            path_count += 1;
            visited[next] = true;
            current = next;
            wanted = if (wanted == color_d) color_c else color_d;
        }
        for (0..path_count) |i| {
            const path_edge = path[i];
            colors[path_edge] = if (colors[path_edge] == color_d) color_c else color_d;
        }

        var prefix_end = fan_count;
        for (0..fan_count) |i| {
            if (mgFree(fan[i], color_d, vertices, edge_at, colors)) {
                prefix_end = i;
                break;
            }
        }
        if (prefix_end == fan_count) return -1;
        var shifted: [6]i64 = @splat(0);
        for (0..prefix_end) |i| shifted[i] = colors[@intCast(edge_at[center * 6 + fan[i + 1]])];
        for (0..prefix_end) |i| colors[@intCast(edge_at[center * 6 + fan[i]])] = shifted[i];
        colors[@intCast(edge_at[center * 6 + fan[prefix_end]])] = color_d;
    }

    var signature: i64 = 0;
    var place: i64 = 1;
    for (0..edge_count) |edge| {
        signature += colors[edge] * place;
        place *= 8;
    }
    return @as(i64, @intCast(palette)) * 262144 + signature;
}
