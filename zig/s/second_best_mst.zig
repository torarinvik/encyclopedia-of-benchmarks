const max_n: usize = 8;
const max_m: usize = 20;

fn findRoot(parent: *[max_n]usize, start: usize) usize {
    var vertex = start;
    while (parent[vertex] != vertex) {
        parent[vertex] = parent[parent[vertex]];
        vertex = parent[vertex];
    }
    return vertex;
}

fn storeI64Le(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn second_best_mst(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 2 or length > 2 + 3 * max_m) return -1;
    const input = input_opt.?;
    const n_value = input[0];
    const m_value = input[1];
    if (n_value < 1 or n_value > 8 or m_value < n_value - 1 or m_value > 20) return -1;
    const n: usize = @intCast(n_value);
    const m: usize = @intCast(m_value);
    if (length != 2 + 3 * m) return -1;

    var edge_u = [_]usize{0} ** max_m;
    var edge_v = [_]usize{0} ** max_m;
    var edge_weight = [_]i64{0} ** max_m;
    var order = [_]usize{0} ** max_m;
    var seen = [_][max_n]bool{[_]bool{false} ** max_n} ** max_n;
    for (0..m) |edge| {
        const u_value = input[2 + 3 * edge];
        const v_value = input[3 + 3 * edge];
        const weight = input[4 + 3 * edge];
        if (u_value < 0 or u_value >= v_value or v_value >= n_value or weight < 0 or weight > 1_000_000) return -1;
        const u: usize = @intCast(u_value);
        const v: usize = @intCast(v_value);
        if (seen[u][v]) return -1;
        seen[u][v] = true;
        edge_u[edge] = u;
        edge_v[edge] = v;
        edge_weight[edge] = weight;
        order[edge] = edge;
    }

    for (1..m) |i| {
        const edge = order[i];
        var j = i;
        while (j > 0 and (edge_weight[order[j - 1]] > edge_weight[edge]
            or (edge_weight[order[j - 1]] == edge_weight[edge] and order[j - 1] > edge))) {
            order[j] = order[j - 1];
            j -= 1;
        }
        order[j] = edge;
    }

    var dsu = [_]usize{0} ** max_n;
    var component_size = [_]usize{0} ** max_n;
    for (0..n) |vertex| {
        dsu[vertex] = vertex;
        component_size[vertex] = 1;
    }
    var in_mst = [_]bool{false} ** max_m;
    var tree_to = [_][max_n]usize{[_]usize{0} ** max_n} ** max_n;
    var tree_edge = [_][max_n]usize{[_]usize{0} ** max_n} ** max_n;
    var degree = [_]usize{0} ** max_n;
    var selected: usize = 0;
    var mst_weight: i64 = 0;
    for (0..m) |position| {
        const edge = order[position];
        var root_u = findRoot(&dsu, edge_u[edge]);
        var root_v = findRoot(&dsu, edge_v[edge]);
        if (root_u == root_v) continue;
        if (component_size[root_u] < component_size[root_v]) {
            const temporary = root_u;
            root_u = root_v;
            root_v = temporary;
        }
        dsu[root_v] = root_u;
        component_size[root_u] += component_size[root_v];
        in_mst[edge] = true;
        selected += 1;
        mst_weight += edge_weight[edge];
        tree_to[edge_u[edge]][degree[edge_u[edge]]] = edge_v[edge];
        tree_edge[edge_u[edge]][degree[edge_u[edge]]] = edge;
        degree[edge_u[edge]] += 1;
        tree_to[edge_v[edge]][degree[edge_v[edge]]] = edge_u[edge];
        tree_edge[edge_v[edge]][degree[edge_v[edge]]] = edge;
        degree[edge_v[edge]] += 1;
    }
    if (selected != n - 1) return -1;

    var second_weight: i64 = -1;
    var entering_edge: i64 = -1;
    var leaving_edge: i64 = -1;
    for (0..m) |added| {
        if (in_mst[added]) continue;
        var parent = [_]i64{-1} ** max_n;
        var parent_edge = [_]i64{-1} ** max_n;
        var queue = [_]usize{0} ** max_n;
        var head: usize = 0;
        var tail: usize = 0;
        const start = edge_u[added];
        const target = edge_v[added];
        parent[start] = @intCast(start);
        queue[tail] = start;
        tail += 1;
        while (head < tail and parent[target] < 0) {
            const vertex = queue[head];
            head += 1;
            for (0..degree[vertex]) |i| {
                const next = tree_to[vertex][i];
                if (parent[next] >= 0) continue;
                parent[next] = @intCast(vertex);
                parent_edge[next] = @intCast(tree_edge[vertex][i]);
                queue[tail] = next;
                tail += 1;
            }
        }
        var first_weight: i64 = -1;
        var second_path_weight: i64 = -1;
        var first_edge: i64 = -1;
        var second_path_edge: i64 = -1;
        var vertex = target;
        while (vertex != start) {
            const path_edge: usize = @intCast(parent_edge[vertex]);
            const weight = edge_weight[path_edge];
            if (weight > first_weight) {
                second_path_weight = first_weight;
                second_path_edge = first_edge;
                first_weight = weight;
                first_edge = @intCast(path_edge);
            } else if (weight == first_weight) {
                if (first_edge < 0 or @as(i64, @intCast(path_edge)) < first_edge) first_edge = @intCast(path_edge);
            } else if (weight > second_path_weight) {
                second_path_weight = weight;
                second_path_edge = @intCast(path_edge);
            } else if (weight == second_path_weight and
                (second_path_edge < 0 or @as(i64, @intCast(path_edge)) < second_path_edge)) {
                second_path_edge = @intCast(path_edge);
            }
            vertex = @intCast(parent[vertex]);
        }
        var removed_weight: i64 = -1;
        var removed_edge: i64 = -1;
        if (edge_weight[added] > first_weight) {
            removed_weight = first_weight;
            removed_edge = first_edge;
        } else if (edge_weight[added] == first_weight and second_path_weight >= 0) {
            removed_weight = second_path_weight;
            removed_edge = second_path_edge;
        }
        if (removed_edge < 0) continue;
        const candidate = mst_weight + edge_weight[added] - removed_weight;
        if (second_weight < 0 or candidate < second_weight or
            (candidate == second_weight and (@as(i64, @intCast(added)) < entering_edge or
            (@as(i64, @intCast(added)) == entering_edge and removed_edge < leaving_edge)))) {
            second_weight = candidate;
            entering_edge = @intCast(added);
            leaving_edge = removed_edge;
        }
    }

    if (output_opt == null or capacity < 32) return -2;
    const output = output_opt.?;
    storeI64Le(output, 0, mst_weight);
    storeI64Le(output, 8, second_weight);
    storeI64Le(output, 16, entering_edge);
    storeI64Le(output, 24, leaving_edge);
    return 32;
}
