// Clean-room bounded GBBS Shiloach-Vishkin spanning-forest profile.
const n_max: usize = 12;
const m_max: usize = 24;
const input_max: usize = 2 + 2 * m_max;

fn findRoot(parent: *[n_max]usize, vertex_in: usize) usize {
    var vertex = vertex_in;
    while (parent[vertex] != vertex) {
        parent[vertex] = parent[parent[vertex]];
        vertex = parent[vertex];
    }
    return vertex;
}

export fn gbbs_shiloach_vishkin_spanning_forest(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 2 or length > input_max) return -1;
    const input = input_opt.?;
    const n64 = input[0];
    const m64 = input[1];
    if (n64 < 1 or n64 > 12 or m64 < 0 or m64 > 24
        or length != 2 + 2 * @as(usize, @intCast(m64))) return -1;
    const n: usize = @intCast(n64);
    const m: usize = @intCast(m64);
    var seen = [_][n_max]bool{[_]bool{false} ** n_max} ** n_max;
    var edge_u = [_]usize{0} ** m_max;
    var edge_v = [_]usize{0} ** m_max;
    for (0..m) |edge| {
        const u64 = input[2 + 2 * edge];
        const v64 = input[3 + 2 * edge];
        if (u64 < 0 or u64 >= n64 or v64 <= u64 or v64 >= n64) return -1;
        const u: usize = @intCast(u64);
        const v: usize = @intCast(v64);
        if (seen[u][v]) return -1;
        seen[u][v] = true;
        edge_u[edge] = u;
        edge_v[edge] = v;
    }
    if (output_opt == null or capacity < m) return -2;
    const output = output_opt.?;

    var parent = [_]usize{0} ** n_max;
    var previous = [_]usize{0} ** n_max;
    var next_parent = [_]usize{0} ** n_max;
    var best_lower = [_]usize{0} ** n_max;
    var selected = [_]u8{0} ** m_max;
    for (0..n) |vertex| parent[vertex] = vertex;
    for (0..n) |_| {
        for (0..n) |vertex| {
            previous[vertex] = findRoot(&parent, vertex);
            next_parent[vertex] = previous[vertex];
            best_lower[vertex] = n;
        }
        for (0..m) |edge| {
            const root_u = previous[edge_u[edge]];
            const root_v = previous[edge_v[edge]];
            if (root_u == root_v) continue;
            const lower = @min(root_u, root_v);
            const higher = @max(root_u, root_v);
            if (previous[higher] == higher and lower < best_lower[higher]) best_lower[higher] = lower;
        }
        var changed = false;
        for (0..n) |higher| {
            const lower = best_lower[higher];
            if (lower == n) continue;
            next_parent[higher] = lower;
            changed = true;
            for (0..m) |edge| {
                const root_u = previous[edge_u[edge]];
                const root_v = previous[edge_v[edge]];
                if ((root_u == higher and root_v == lower) or (root_u == lower and root_v == higher)) {
                    selected[edge] = 1;
                    break;
                }
            }
        }
        for (0..n) |vertex| parent[vertex] = findRoot(&next_parent, vertex);
        if (!changed) break;
    }
    for (0..m) |edge| output[edge] = selected[edge];
    return @intCast(m);
}
