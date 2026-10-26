// Clean-room bounded GBBS Tarjan-Vishkin biconnectivity profile.
const n_max: usize = 12;
const m_max: usize = 24;
const input_max: usize = 2 + 2 * m_max;

fn treeEdge(u: usize, v: usize, parent: *const [n_max]usize) bool {
    return parent[u] == v or parent[v] == u;
}
fn criticalEdge(u: usize, v: usize, parent: *const [n_max]usize,
    critical: *const [n_max]bool) bool {
    if (parent[u] == v) return critical[u];
    if (parent[v] == u) return critical[v];
    return false;
}
fn parentsBfs(n: usize, adjacent: *const [n_max][n_max]bool,
    parent: *[n_max]usize, seen: *[n_max]bool) void {
    var frontier: [n_max]usize = undefined;
    var next: [n_max]usize = undefined;
    var candidate: [n_max]usize = undefined;
    for (0..n) |root| {
        if (seen[root]) continue;
        var count: usize = 1;
        frontier[0] = root;
        parent[root] = root;
        seen[root] = true;
        while (count != 0) {
            var has = [_]bool{false} ** n_max;
            for (0..count) |i| {
                const vertex = frontier[i];
                for (0..n) |other| {
                    if (adjacent[vertex][other] and !seen[other]) {
                        if (!has[other] or vertex < candidate[other]) candidate[other] = vertex;
                        has[other] = true;
                    }
                }
            }
            var next_count: usize = 0;
            for (0..n) |other| {
                if (has[other]) {
                    parent[other] = candidate[other];
                    seen[other] = true;
                    next[next_count] = other;
                    next_count += 1;
                }
            }
            @memcpy(frontier[0..next_count], next[0..next_count]);
            count = next_count;
        }
    }
}
fn assignPreorder(n: usize, parent: *const [n_max]usize,
    pn: *[n_max]usize, order: *[n_max]usize, size: *[n_max]usize) void {
    var stack: [n_max]usize = undefined;
    var global: usize = 0;
    for (0..n) |root| {
        if (parent[root] != root) continue;
        var top: usize = 0;
        var count: usize = 0;
        const begin = global;
        stack[top] = root;
        top += 1;
        while (top != 0) {
            top -= 1;
            const vertex = stack[top];
            pn[vertex] = count;
            count += 1;
            order[global] = vertex;
            global += 1;
            var child = n;
            while (child > 0) {
                child -= 1;
                if (child != vertex and parent[child] == vertex) {
                    stack[top] = child;
                    top += 1;
                }
            }
        }
        var i = global;
        while (i > begin) {
            i -= 1;
            const vertex = order[i];
            if (parent[vertex] != vertex) size[parent[vertex]] += size[vertex];
        }
    }
}

export fn gbbs_biconnectivity(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 2 or length > input_max) return -1;
    const input = input_opt.?;
    const n64 = input[0];
    const m64 = input[1];
    if (n64 < 1 or n64 > 12 or m64 < 0 or m64 > 24 or
        length != 2 + 2 * @as(usize, @intCast(m64))) return -1;
    const n: usize = @intCast(n64);
    const m: usize = @intCast(m64);
    var adjacent = [_][n_max]bool{[_]bool{false} ** n_max} ** n_max;
    for (0..m) |edge| {
        const u64 = input[2 + 2 * edge];
        const v64 = input[3 + 2 * edge];
        if (u64 < 0 or v64 <= u64 or v64 >= n64) return -1;
        const u: usize = @intCast(u64);
        const v: usize = @intCast(v64);
        if (adjacent[u][v]) return -1;
        adjacent[u][v] = true;
        adjacent[v][u] = true;
    }
    if (output_opt == null or capacity < m) return -2;
    const output = output_opt.?;
    var parent = [_]usize{0} ** n_max;
    var pn = [_]usize{0} ** n_max;
    var order = [_]usize{0} ** n_max;
    var size = [_]usize{1} ** n_max;
    var seen = [_]bool{false} ** n_max;
    var critical = [_]bool{false} ** n_max;
    for (0..n) |v| parent[v] = v;
    parentsBfs(n, &adjacent, &parent, &seen);
    assignPreorder(n, &parent, &pn, &order, &size);
    var low = pn;
    var high = [_]usize{0} ** n_max;
    for (0..n) |v| high[v] = pn[v] + size[v] - 1;
    for (0..m) |edge| {
        const u: usize = @intCast(input[2 + 2 * edge]);
        const v: usize = @intCast(input[3 + 2 * edge]);
        if (!treeEdge(u, v, &parent)) {
            if (pn[u] < low[v]) low[v] = pn[u] else if (pn[u] > high[v]) high[v] = pn[u];
            if (pn[v] < low[u]) low[u] = pn[v] else if (pn[v] > high[u]) high[u] = pn[v];
        }
    }
    var i = n;
    while (i > 0) {
        i -= 1;
        const vertex = order[i];
        if (parent[vertex] != vertex) {
            const p = parent[vertex];
            low[p] = @min(low[p], low[vertex]);
            high[p] = @max(high[p], high[vertex]);
        }
    }
    for (0..n) |v| {
        const p = parent[v];
        if (v != p and low[v] >= pn[p] and high[v] < pn[p] + size[p]) critical[v] = true;
    }
    var component = [_]usize{n_max} ** n_max;
    var queue = [_]usize{0} ** n_max;
    for (0..n) |root| {
        if (component[root] != n_max) continue;
        var head: usize = 0;
        var tail: usize = 0;
        component[root] = root;
        queue[tail] = root;
        tail += 1;
        while (head < tail) {
            const vertex = queue[head];
            head += 1;
            for (0..n) |other| {
                if (adjacent[vertex][other] and !criticalEdge(vertex, other, &parent, &critical)
                    and component[other] == n_max) {
                    component[other] = root;
                    queue[tail] = other;
                    tail += 1;
                }
            }
        }
    }
    var raw = [_]usize{0} ** m_max;
    for (0..m) |edge| {
        const u: usize = @intCast(input[2 + 2 * edge]);
        const v: usize = @intCast(input[3 + 2 * edge]);
        if (parent[u] == v and critical[u]) raw[edge] = component[u]
        else if (parent[v] == u and critical[v]) raw[edge] = component[v]
        else raw[edge] = component[u];
    }
    for (0..m) |edge| {
        var label = m;
        for (0..m) |other| {
            if (raw[other] == raw[edge]) label = @min(label, other);
        }
        output[edge] = @intCast(label);
    }
    return @intCast(m);
}
