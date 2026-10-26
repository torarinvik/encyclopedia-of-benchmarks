// Clean-room bounded port of GAPBS OrderedCount; see package LICENSE.txt.
const max_n: usize = 16;

export fn gapbs_ordered_triangle_count(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length < 2 or length > 1 + max_n * max_n) return -1;
    const input = input_opt.?;
    if (input[0] < 1 or input[0] > @as(i64, @intCast(max_n))) return -1;
    const n: usize = @intCast(input[0]);
    if (length != 1 + n * n) return -1;
    var adjacency: [max_n][max_n]i64 = [_][max_n]i64{[_]i64{0} ** max_n} ** max_n;
    var neighbors: [max_n][max_n]usize = [_][max_n]usize{[_]usize{0} ** max_n} ** max_n;
    var degree: [max_n]usize = [_]usize{0} ** max_n;
    for (0..n) |u| {
        for (0..n) |v| {
            const edge = input[1 + u * n + v];
            if ((edge != 0 and edge != 1) or (u == v and edge != 0)) return -1;
            adjacency[u][v] = edge;
        }
    }
    for (0..n) |u| {
        for (u + 1..n) |v| {
            if (adjacency[u][v] != adjacency[v][u]) return -1;
        }
    }
    for (0..n) |u| {
        for (0..n) |v| {
            if (adjacency[u][v] != 0) {
                neighbors[u][degree[u]] = v;
                degree[u] += 1;
            }
        }
    }
    var total: i64 = 0;
    for (0..n) |u| {
        for (0..degree[u]) |vi| {
            const v = neighbors[u][vi];
            if (v > u) break;
            var edge_pos: usize = 0;
            for (0..degree[u]) |wi| {
                const w = neighbors[u][wi];
                if (w > v) break;
                while (edge_pos < degree[v] and neighbors[v][edge_pos] < w) : (edge_pos += 1) {}
                if (edge_pos < degree[v] and neighbors[v][edge_pos] == w) total += 1;
            }
        }
    }
    return total;
}
