const MAX_NODES: usize = 64;

fn find_root(parent: *[MAX_NODES]usize, start: usize) usize {
    var vertex = start;
    while (parent[vertex] != vertex) {
        parent[vertex] = parent[parent[vertex]];
        vertex = parent[vertex];
    }
    return vertex;
}

export fn lca(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length < 3 or length > 129) return -1;
    const input = input_opt.?;
    if (input[0] < 1 or input[0] > 64) return -1;
    const n: usize = @intCast(input[0]);
    if (length != 2 * n + 1) return -1;
    var dsu: [MAX_NODES]usize = undefined;
    var degree: [MAX_NODES]usize = [_]usize{0} ** MAX_NODES;
    var adjacency: [MAX_NODES][MAX_NODES]usize = undefined;
    for (0..n) |i| dsu[i] = i;
    var pos: usize = 1;
    for (0..n - 1) |_| {
        const u_arg = input[pos];
        const v_arg = input[pos + 1];
        pos += 2;
        if (u_arg < 0 or u_arg >= @as(i64, @intCast(n)) or v_arg < 0 or
            v_arg >= @as(i64, @intCast(n)) or u_arg == v_arg) return -1;
        const u: usize = @intCast(u_arg);
        const v: usize = @intCast(v_arg);
        const ru = find_root(&dsu, u);
        const rv = find_root(&dsu, v);
        if (ru == rv) return -1;
        dsu[ru] = rv;
        adjacency[u][degree[u]] = v;
        degree[u] += 1;
        adjacency[v][degree[v]] = u;
        degree[v] += 1;
    }
    const qa_arg = input[pos];
    const qb_arg = input[pos + 1];
    if (qa_arg < 0 or qa_arg >= @as(i64, @intCast(n)) or qb_arg < 0 or
        qb_arg >= @as(i64, @intCast(n))) return -1;
    const component = find_root(&dsu, 0);
    for (1..n) |i| if (find_root(&dsu, i) != component) return -1;

    var parent: [MAX_NODES]usize = undefined;
    var depth: [MAX_NODES]usize = undefined;
    var stack: [MAX_NODES]usize = undefined;
    var seen: [MAX_NODES]bool = [_]bool{false} ** MAX_NODES;
    var stack_size: usize = 1;
    stack[0] = 0;
    seen[0] = true;
    while (stack_size > 0) {
        stack_size -= 1;
        const vertex = stack[stack_size];
        for (0..degree[vertex]) |i| {
            const next = adjacency[vertex][i];
            if (!seen[next]) {
                seen[next] = true;
                parent[next] = vertex;
                depth[next] = depth[vertex] + 1;
                stack[stack_size] = next;
                stack_size += 1;
            }
        }
    }
    var a: usize = @intCast(qa_arg);
    var b: usize = @intCast(qb_arg);
    if (depth[a] < depth[b]) { const t = a; a = b; b = t; }
    while (depth[a] != depth[b]) a = parent[a];
    if (a == b) return @intCast(a);
    while (a != b) { a = parent[a]; b = parent[b]; }
    return @intCast(a);
}
