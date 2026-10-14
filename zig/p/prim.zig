/// Dense Prim scan over a bounded packed undirected edge list.
export fn prim(values: [*]const i64, length: usize) i64 {
    if (length < 2 or length > 12290) return -2;
    if (values[0] < 0 or values[0] > 64 or values[1] < 0 or values[1] > 4096) return -2;
    const vertices: usize = @intCast(values[0]);
    const edges: usize = @intCast(values[1]);
    if (length != 2 + 3 * edges or (vertices == 0 and edges != 0)) return -2;
    if (vertices == 0) return 0;

    var present: [4096]bool = undefined;
    var weights: [4096]i64 = undefined;
    for (0..4096) |slot| {
        present[slot] = false;
        weights[slot] = 0;
    }
    for (0..edges) |edge| {
        const u_value = values[2 + 3 * edge];
        const v_value = values[3 + 3 * edge];
        const cost = values[4 + 3 * edge];
        if (u_value < 0 or v_value < 0 or u_value >= @as(i64, @intCast(vertices)) or
            v_value >= @as(i64, @intCast(vertices)) or cost < 0 or cost > 2147483647) return -2;
        const u: usize = @intCast(u_value);
        const v: usize = @intCast(v_value);
        if (u != v) {
            const uv = u * 64 + v;
            const vu = v * 64 + u;
            if (!present[uv] or cost < weights[uv]) {
                present[uv] = true;
                present[vu] = true;
                weights[uv] = cost;
                weights[vu] = cost;
            }
        }
    }

    var in_tree: [64]bool = undefined;
    var has_best: [64]bool = undefined;
    var best: [64]i64 = undefined;
    for (0..64) |vertex| {
        in_tree[vertex] = false;
        has_best[vertex] = false;
        best[vertex] = 0;
    }
    has_best[0] = true;
    var total: i64 = 0;
    for (0..vertices) |_| {
        var selected = vertices;
        for (0..vertices) |vertex| {
            if (!in_tree[vertex] and has_best[vertex] and
                (selected == vertices or best[vertex] < best[selected])) selected = vertex;
        }
        if (selected == vertices) return -1;
        in_tree[selected] = true;
        total += best[selected];
        for (0..vertices) |vertex| {
            const slot = selected * 64 + vertex;
            if (!in_tree[vertex] and present[slot] and (!has_best[vertex] or weights[slot] < best[vertex])) {
                has_best[vertex] = true;
                best[vertex] = weights[slot];
            }
        }
    }
    return total;
}
