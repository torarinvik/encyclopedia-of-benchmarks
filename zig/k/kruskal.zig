fn siftDown(keys: []i64, start_root: usize, end: usize) void {
    var root = start_root;
    while (root < end / 2) {
        var child = root * 2 + 1;
        if (child + 1 < end and keys[child] < keys[child + 1]) child += 1;
        if (keys[root] >= keys[child]) break;
        const temporary = keys[root]; keys[root] = keys[child]; keys[child] = temporary;
        root = child;
    }
}
fn findRoot(parent: *[64]usize, start_node: usize) usize {
    var node = start_node;
    while (parent[node] != node) { parent[node] = parent[parent[node]]; node = parent[node]; }
    return node;
}
/// Heapsort packed undirected edges, then build an MST with union by rank.
export fn kruskal(values: [*]const i64, length: usize) i64 {
    if (length < 2 or length > 12290) return -2;
    if (values[0] < 0 or values[0] > 64 or values[1] < 0 or values[1] > 4096) return -2;
    const vertices: usize = @intCast(values[0]); const edges: usize = @intCast(values[1]);
    if (length != 2 + 3 * edges or (vertices == 0 and edges != 0)) return -2;
    if (vertices == 0) return 0;
    var keys: [4096]i64 = undefined;
    for (0..edges) |edge| {
        var u = values[2 + 3 * edge]; var v = values[3 + 3 * edge]; const weight = values[4 + 3 * edge];
        if (u < 0 or v < 0 or u >= @as(i64, @intCast(vertices)) or v >= @as(i64, @intCast(vertices)) or weight < 0 or weight > 2147483647) return -2;
        if (u > v) { const temporary = u; u = v; v = temporary; }
        keys[edge] = weight * 4096 + u * 64 + v;
    }
    for (0..edges / 2) |offset| siftDown(keys[0..edges], edges / 2 - 1 - offset, edges);
    var end = edges;
    while (end > 1) { end -= 1; const temporary = keys[0]; keys[0] = keys[end]; keys[end] = temporary; siftDown(keys[0..edges], 0, end); }
    var parent: [64]usize = undefined; var rank: [64]usize = undefined;
    for (0..64) |vertex| { parent[vertex] = vertex; rank[vertex] = 0; }
    var selected: usize = 0; var total: i64 = 0;
    for (0..edges) |edge| {
        if (selected + 1 >= vertices) break;
        const key = keys[edge]; const u: usize = @intCast(@divTrunc(@mod(key, 4096), 64)); const v: usize = @intCast(@mod(key, 64));
        const root_u = findRoot(&parent, u); const root_v = findRoot(&parent, v);
        if (root_u != root_v) {
            total += @divTrunc(key, 4096); selected += 1;
            if (rank[root_u] < rank[root_v]) { parent[root_u] = root_v; }
            else if (rank[root_u] > rank[root_v]) { parent[root_v] = root_u; }
            else { parent[root_v] = root_u; rank[root_u] += 1; }
        }
    }
    return if (selected + 1 == vertices) total else -1;
}
