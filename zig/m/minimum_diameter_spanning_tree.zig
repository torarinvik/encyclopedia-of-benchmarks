const max_n: usize = 8;
const max_m: usize = 20;
const max_input_values: usize = 2 + 3 * max_m + 1;
const infinity: i64 = 1_000_000_000_000;

const Edge = struct { u: usize, v: usize, weight: i64 };

fn shortestTree(n: usize, edges: []const Edge, m: usize, center_kind: i64,
    center_root: usize, center_x2: i64, center_edge: usize,
    distance: *[max_n]i64, parent_edge: *[max_n]i64) void {
    var settled = [_]bool{false} ** max_n;
    distance.* = [_]i64{infinity} ** max_n;
    parent_edge.* = [_]i64{-1} ** max_n;
    if (center_kind == 0) {
        distance[center_root] = 0;
    } else {
        var u = edges[center_edge].u;
        var v = edges[center_edge].v;
        if (u > v) {
            const temporary = u;
            u = v;
            v = temporary;
        }
        distance[u] = center_x2;
        distance[v] = 2 * edges[center_edge].weight - center_x2;
    }
    for (0..n) |_| {
        var current: usize = n;
        for (0..n) |vertex| {
            if (!settled[vertex] and
                (current == n or distance[vertex] < distance[current])) current = vertex;
        }
        if (current == n or distance[current] == infinity) return;
        settled[current] = true;
        for (0..m) |edge_id| {
            const left = edges[edge_id].u;
            const right = edges[edge_id].v;
            if (left == right) continue;
            var neighbor: usize = n;
            if (current == left) neighbor = right else if (current == right) neighbor = left else continue;
            const candidate = distance[current] + 2 * edges[edge_id].weight;
            if (!settled[neighbor] and candidate < distance[neighbor]) {
                distance[neighbor] = candidate;
                parent_edge[neighbor] = @intCast(edge_id);
            }
        }
    }
}

fn selectedTreeDiameter(n: usize, edges: []const Edge, selected: *[max_n]usize) i64 {
    var adjacent = [_][max_n]bool{[_]bool{false} ** max_n} ** max_n;
    var weight = [_][max_n]i64{[_]i64{0} ** max_n} ** max_n;
    for (0..n - 1) |index| {
        const edge = edges[selected[index]];
        adjacent[edge.u][edge.v] = true;
        adjacent[edge.v][edge.u] = true;
        weight[edge.u][edge.v] = edge.weight;
        weight[edge.v][edge.u] = edge.weight;
    }
    var diameter: i64 = 0;
    for (0..n) |source| {
        var distance = [_]i64{-1} ** max_n;
        var parent = [_]usize{n} ** max_n;
        var stack = [_]usize{0} ** max_n;
        var top: usize = 1;
        stack[0] = source;
        distance[source] = 0;
        while (top > 0) {
            top -= 1;
            const current = stack[top];
            diameter = @max(diameter, distance[current]);
            for (0..n) |neighbor| {
                if (adjacent[current][neighbor] and parent[current] != neighbor and distance[neighbor] < 0) {
                    parent[neighbor] = current;
                    distance[neighbor] = distance[current] + weight[current][neighbor];
                    stack[top] = neighbor;
                    top += 1;
                }
            }
        }
    }
    return diameter;
}

fn storeI64Le(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn minimum_diameter_spanning_tree(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 2 or length > max_input_values) return -1;
    const input = input_opt.?;
    const n_value = input[0];
    const m_value = input[1];
    if (n_value < 1 or n_value > @as(i64, @intCast(max_n)) or
        m_value < 0 or m_value > @as(i64, @intCast(max_m))) return -1;
    const n: usize = @intCast(n_value);
    const m: usize = @intCast(m_value);
    if (length != 2 + 3 * m) return -1;

    var edges: [max_m]Edge = undefined;
    var graph_distance = [_][max_n]i64{[_]i64{infinity} ** max_n} ** max_n;
    for (0..n) |vertex| graph_distance[vertex][vertex] = 0;
    for (0..m) |edge_id| {
        const offset = 2 + 3 * edge_id;
        const u_value = input[offset];
        const v_value = input[offset + 1];
        const edge_weight = input[offset + 2];
        if (u_value < 0 or u_value >= n_value or v_value < 0 or v_value >= n_value or
            edge_weight < 0 or edge_weight > 9) return -1;
        const u: usize = @intCast(u_value);
        const v: usize = @intCast(v_value);
        edges[edge_id] = .{ .u = u, .v = v, .weight = edge_weight };
        if (u != v and edge_weight < graph_distance[u][v]) {
            graph_distance[u][v] = edge_weight;
            graph_distance[v][u] = edge_weight;
        }
    }
    for (0..n) |middle| {
        for (0..n) |left| {
            for (0..n) |right| {
                graph_distance[left][right] = @min(graph_distance[left][right],
                    graph_distance[left][middle] + graph_distance[middle][right]);
            }
        }
    }
    for (0..n) |vertex| if (graph_distance[0][vertex] == infinity) return -1;

    var best_radius2 = infinity;
    var best_kind: i64 = 0;
    var best_root: usize = 0;
    var best_x2: i64 = 0;
    var best_edge: usize = 0;
    for (0..n) |root| {
        var eccentricity: i64 = 0;
        for (0..n) |vertex| eccentricity = @max(eccentricity, graph_distance[root][vertex]);
        const radius2 = 2 * eccentricity;
        if (radius2 < best_radius2) {
            best_radius2 = radius2;
            best_kind = 0;
            best_root = root;
        }
    }
    for (0..m) |edge_id| {
        var u = edges[edge_id].u;
        var v = edges[edge_id].v;
        const edge_weight = edges[edge_id].weight;
        if (u == v) continue;
        if (u > v) {
            const temporary = u;
            u = v;
            v = temporary;
        }
        var x2: i64 = 0;
        while (x2 <= 2 * edge_weight) : (x2 += 1) {
            var radius2: i64 = 0;
            for (0..n) |vertex| {
                const from_u = 2 * graph_distance[u][vertex] + x2;
                const from_v = 2 * graph_distance[v][vertex] + 2 * edge_weight - x2;
                radius2 = @max(radius2, @min(from_u, from_v));
            }
            if (radius2 < best_radius2) {
                best_radius2 = radius2;
                best_kind = 1;
                best_root = u;
                best_x2 = x2;
                best_edge = edge_id;
            }
        }
    }

    var center_distance = [_]i64{0} ** max_n;
    var parent_edge = [_]i64{0} ** max_n;
    shortestTree(n, edges[0..], m, best_kind, best_root, best_x2, best_edge,
        &center_distance, &parent_edge);
    var selected = [_]usize{0} ** max_n;
    var selected_count: usize = 0;
    for (0..n) |vertex| {
        if (parent_edge[vertex] >= 0) {
            selected[selected_count] = @intCast(parent_edge[vertex]);
            selected_count += 1;
        }
    }
    if (selected_count + 2 == n and best_kind == 1) {
        const u = edges[best_edge].u;
        const v = edges[best_edge].v;
        if (parent_edge[u] == -1 and parent_edge[v] == -1) {
            selected[selected_count] = best_edge;
            selected_count += 1;
        }
    }
    if (selected_count != n - 1) return -1;
    for (0..selected_count) |left| {
        for (left + 1..selected_count) |right| {
            if (selected[right] < selected[left]) {
                const temporary = selected[left];
                selected[left] = selected[right];
                selected[right] = temporary;
            }
        }
    }

    var staged = [_]i64{0} ** max_n;
    staged[0] = selectedTreeDiameter(n, edges[0..], &selected);
    for (0..selected_count) |index| staged[index + 1] = @intCast(selected[index]);
    const required = 8 * n;
    if (output_opt == null or capacity < required) return -2;
    const output = output_opt.?;
    for (0..n) |index| storeI64Le(output, 8 * index, staged[index]);
    return @intCast(required);
}
