// Clean-room bounded rotation-system planarity recognizer.
const MAX_N: usize = 6;
const MAX_M: usize = 15;
const MAX_DARTS: usize = 30;

export fn rotation_system_planarity_test(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length < 2 or length > 33) return -1;
    const input = input_opt.?;
    const n64 = input[0];
    const m64 = input[1];
    if (n64 < 1 or n64 > 6 or m64 < 0 or m64 > 15 or length != 2 + 2 * @as(usize, @intCast(m64))) return -1;
    const n: usize = @intCast(n64);
    const m: usize = @intCast(m64);
    var adjacent = [_]bool{false} ** (MAX_N * MAX_N);
    var edge_u = [_]usize{0} ** MAX_M;
    var edge_v = [_]usize{0} ** MAX_M;
    for (0..m) |edge| {
        const u64 = input[2 + 2 * edge];
        const v64 = input[3 + 2 * edge];
        if (u64 < 0 or u64 >= v64 or v64 >= n64) return -1;
        const u: usize = @intCast(u64);
        const v: usize = @intCast(v64);
        if (adjacent[u * MAX_N + v]) return -1;
        adjacent[u * MAX_N + v] = true;
        adjacent[v * MAX_N + u] = true;
        edge_u[edge] = u;
        edge_v[edge] = v;
    }
    if (n >= 3 and m > 3 * n - 6) return 0;
    var edge_id = [_]i32{-1} ** (MAX_N * MAX_N);
    var neighbors = [_]usize{0} ** (MAX_N * MAX_N);
    var degree = [_]usize{0} ** MAX_N;
    for (0..m) |edge| {
        edge_id[edge_u[edge] * MAX_N + edge_v[edge]] = @intCast(edge);
        edge_id[edge_v[edge] * MAX_N + edge_u[edge]] = @intCast(edge);
    }
    for (0..n) |u| {
        for (0..n) |v| {
            if (adjacent[u * MAX_N + v]) {
                neighbors[u * MAX_N + degree[u]] = v;
                degree[u] += 1;
            }
        }
    }
    var component = [_]i32{-1} ** MAX_N;
    var component_vertices = [_]usize{0} ** (MAX_N * MAX_N);
    var component_size = [_]usize{0} ** MAX_N;
    var component_count: usize = 0;
    for (0..n) |root| {
        if (component[root] == -1) {
            const cid = component_count;
            component_count += 1;
            var queue = [_]usize{0} ** MAX_N;
            var head: usize = 0;
            var tail: usize = 0;
            component[root] = @intCast(cid);
            queue[tail] = root;
            tail += 1;
            while (head < tail) {
                const here = queue[head];
                head += 1;
                component_vertices[cid * MAX_N + component_size[cid]] = here;
                component_size[cid] += 1;
                for (0..n) |there| {
                    if (adjacent[here * MAX_N + there] and component[there] == -1) {
                        component[there] = @intCast(cid);
                        queue[tail] = there;
                        tail += 1;
                    }
                }
            }
        }
    }
    for (0..component_count) |cid| {
        var component_edges: usize = 0;
        for (0..m) |edge| {
            if (component[edge_u[edge]] == @as(i32, @intCast(cid))) component_edges += 1;
        }
        if (component_size[cid] >= 3 and component_edges > 3 * component_size[cid] - 6) return 0;
        if (component_size[cid] == 1) continue;
        var rotation = [_]usize{0} ** (MAX_N * MAX_N);
        for (0..component_size[cid]) |i| {
            const vertex = component_vertices[cid * MAX_N + i];
            for (0..degree[vertex]) |j| rotation[vertex * MAX_N + j] = neighbors[vertex * MAX_N + j];
        }
        var found = false;
        var done = false;
        while (!found and !done) {
            var successor = [_]i32{-1} ** MAX_DARTS;
            for (0..component_size[cid]) |i| {
                const vertex = component_vertices[cid * MAX_N + i];
                const d = degree[vertex];
                for (0..d) |j| {
                    const next = (j + 1) % d;
                    const edge: usize = @intCast(edge_id[vertex * MAX_N + rotation[vertex * MAX_N + j]]);
                    const next_edge: usize = @intCast(edge_id[vertex * MAX_N + rotation[vertex * MAX_N + next]]);
                    var dart = 2 * edge;
                    if (edge_u[edge] != vertex) dart += 1;
                    var next_dart = 2 * next_edge;
                    if (edge_u[next_edge] != vertex) next_dart += 1;
                    successor[dart] = @intCast(next_dart);
                }
            }
            var used = [_]bool{false} ** MAX_DARTS;
            var faces: i32 = 0;
            for (0..m) |edge| {
                if (component[edge_u[edge]] == @as(i32, @intCast(cid))) {
                    for (0..2) |orientation| {
                        var dart = 2 * edge + orientation;
                        if (!used[dart]) {
                            faces += 1;
                            while (!used[dart]) {
                                used[dart] = true;
                                dart = @intCast(successor[dart ^ 1]);
                            }
                        }
                    }
                }
            }
            const euler_characteristic = @as(i32, @intCast(component_size[cid])) - @as(i32, @intCast(component_edges)) + faces;
            if (euler_characteristic == 2) {
                found = true;
            } else {
                var position: i32 = @as(i32, @intCast(component_size[cid])) - 1;
                var advanced = false;
                while (position >= 0 and !advanced) {
                    const vertex = component_vertices[cid * MAX_N + @as(usize, @intCast(position))];
                    const d = degree[vertex];
                    var pivot: i32 = @as(i32, @intCast(d)) - 2;
                    while (pivot >= 1 and rotation[vertex * MAX_N + @as(usize, @intCast(pivot))] >= rotation[vertex * MAX_N + @as(usize, @intCast(pivot)) + 1]) pivot -= 1;
                    if (pivot >= 1) {
                        var swap_at = d - 1;
                        while (rotation[vertex * MAX_N + swap_at] <= rotation[vertex * MAX_N + @as(usize, @intCast(pivot))]) swap_at -= 1;
                        const pivot_index: usize = @intCast(pivot);
                        const temp = rotation[vertex * MAX_N + pivot_index];
                        rotation[vertex * MAX_N + pivot_index] = rotation[vertex * MAX_N + swap_at];
                        rotation[vertex * MAX_N + swap_at] = temp;
                        var left = pivot_index + 1;
                        var right = d - 1;
                        while (left < right) {
                            const value = rotation[vertex * MAX_N + left];
                            rotation[vertex * MAX_N + left] = rotation[vertex * MAX_N + right];
                            rotation[vertex * MAX_N + right] = value;
                            left += 1;
                            right -= 1;
                        }
                        advanced = true;
                    } else {
                        for (0..d) |j| rotation[vertex * MAX_N + j] = neighbors[vertex * MAX_N + j];
                        position -= 1;
                    }
                }
                if (!advanced) done = true;
            }
        }
        if (!found) return 0;
    }
    return 1;
}
