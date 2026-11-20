// Clean-room Goldberg exact maximum-density profile.
const MAX_N: usize = 8;
const MAX_M: usize = 28;
const MAX_NETWORK: usize = 10;

export fn goldberg_maximum_density_subgraph(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length < 2 or length > 59) return -1;
    const input = input_opt.?;
    const n64 = input[0];
    const m64 = input[1];
    if (n64 < 2 or n64 > 8 or m64 < 0 or m64 > 28 or length != 2 + 2 * @as(usize, @intCast(m64))) return -1;
    const n: usize = @intCast(n64);
    const m: usize = @intCast(m64);
    var adjacent = [_]bool{false} ** (MAX_N * MAX_N);
    var degree = [_]i64{0} ** MAX_N;
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
        degree[u] += 1;
        degree[v] += 1;
    }
    if (m == 0) return 1;

    var low: i64 = 0;
    var high: i64 = m64;
    var denominator: i64 = 1;
    var best = [_]bool{false} ** MAX_N;
    while ((high - low) * n64 * (n64 - 1) >= denominator) {
        const low2 = 2 * low;
        const high2 = 2 * high;
        const midpoint = low + high;
        const next_denominator = 2 * denominator;
        const source = n;
        const sink = n + 1;
        const network_size = n + 2;
        var residual = [_]i64{0} ** (MAX_NETWORK * MAX_NETWORK);
        for (0..n) |v| {
            const source_capacity = m64 * next_denominator;
            residual[source * MAX_NETWORK + v] = source_capacity;
            residual[v * MAX_NETWORK + sink] = source_capacity + 2 * midpoint - next_denominator * degree[v];
        }
        for (0..m) |edge| {
            const u = edge_u[edge];
            const v = edge_v[edge];
            residual[u * MAX_NETWORK + v] += next_denominator;
            residual[v * MAX_NETWORK + u] += next_denominator;
        }
        while (true) {
            var parent = [_]i32{-1} ** MAX_NETWORK;
            var queue = [_]usize{0} ** MAX_NETWORK;
            var head: usize = 0;
            var tail: usize = 0;
            parent[source] = @intCast(source);
            queue[tail] = source;
            tail += 1;
            while (head < tail and parent[sink] == -1) {
                const here = queue[head];
                head += 1;
                for (0..network_size) |there| {
                    if (parent[there] == -1 and residual[here * MAX_NETWORK + there] > 0) {
                        parent[there] = @intCast(here);
                        queue[tail] = there;
                        tail += 1;
                        if (there == sink) break;
                    }
                }
            }
            if (parent[sink] == -1) break;
            var amount: i64 = 1 << 60;
            var vertex = sink;
            while (vertex != source) {
                const previous: usize = @intCast(parent[vertex]);
                amount = @min(amount, residual[previous * MAX_NETWORK + vertex]);
                vertex = previous;
            }
            vertex = sink;
            while (vertex != source) {
                const previous: usize = @intCast(parent[vertex]);
                residual[previous * MAX_NETWORK + vertex] -= amount;
                residual[vertex * MAX_NETWORK + previous] += amount;
                vertex = previous;
            }
        }
        var reachable = [_]bool{false} ** MAX_NETWORK;
        var queue2 = [_]usize{0} ** MAX_NETWORK;
        var head2: usize = 0;
        var tail2: usize = 0;
        reachable[source] = true;
        queue2[tail2] = source;
        tail2 += 1;
        while (head2 < tail2) {
            const here = queue2[head2];
            head2 += 1;
            for (0..network_size) |there| {
                if (!reachable[there] and residual[here * MAX_NETWORK + there] > 0) {
                    reachable[there] = true;
                    queue2[tail2] = there;
                    tail2 += 1;
                }
            }
        }
        var selected = [_]bool{false} ** MAX_N;
        var any = false;
        for (0..n) |v| {
            selected[v] = reachable[v];
            any = any or selected[v];
        }
        if (any) {
            best = selected;
            low = midpoint;
            high = high2;
        } else {
            low = low2;
            high = midpoint;
        }
        denominator = next_denominator;
    }
    var vertex_count: i64 = 0;
    var edge_count: i64 = 0;
    for (0..n) |v| {
        if (best[v]) vertex_count += 1;
    }
    if (vertex_count == 0) return 1;
    for (0..m) |edge| {
        if (best[edge_u[edge]] and best[edge_v[edge]]) edge_count += 1;
    }
    var a = edge_count;
    var b = vertex_count;
    while (b != 0) {
        const r = @mod(a, b);
        a = b;
        b = r;
    }
    return (edge_count / a) * (n64 + 1) + vertex_count / a;
}
