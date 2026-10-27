const max_n: usize = 8;
const max_m: usize = 28;
const max_input: usize = 88;
const inf: i64 = 1 << 60;

export fn weighted_greedy_spanner(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 3 or length > max_input) return -1;
    const input = input_opt.?;
    const n64, const m64, const k = input[0], input[1], input[2];
    if (n64 < 2 or n64 > 8 or m64 < 0 or m64 > 28 or k < 1 or k > 3 or
        length != 3 + 3 * @as(usize, @intCast(m64))) return -1;
    const n: usize = @intCast(n64);
    const m: usize = @intCast(m64);
    var edge_u: [max_m]i64 = [_]i64{0} ** max_m;
    var edge_v: [max_m]i64 = [_]i64{0} ** max_m;
    var edge_w: [max_m]i64 = [_]i64{0} ** max_m;
    var order: [max_m]usize = [_]usize{0} ** max_m;
    var adjacency: [max_n][max_n]i64 = [_][max_n]i64{[_]i64{0} ** max_n} ** max_n;
    var selected: [max_m]u8 = [_]u8{0} ** max_m;
    for (0..m) |i| {
        edge_u[i] = input[3 + 3 * i];
        edge_v[i] = input[4 + 3 * i];
        edge_w[i] = input[5 + 3 * i];
        if (edge_u[i] < 0 or edge_v[i] <= edge_u[i] or edge_v[i] >= n64 or edge_w[i] < 1 or edge_w[i] > 32) return -1;
        for (0..i) |j| if (edge_u[j] == edge_u[i] and edge_v[j] == edge_v[i]) return -1;
        order[i] = i;
    }
    for (1..m) |i| {
        const key = order[i];
        var pos = i;
        while (pos > 0) {
            const prev = order[pos - 1];
            if (edge_w[prev] < edge_w[key] or (edge_w[prev] == edge_w[key] and edge_u[prev] < edge_u[key]) or
                (edge_w[prev] == edge_w[key] and edge_u[prev] == edge_u[key] and edge_v[prev] <= edge_v[key])) break;
            order[pos] = prev;
            pos -= 1;
        }
        order[pos] = key;
    }
    if (output_opt == null or capacity < m) return -2;
    const output = output_opt.?;
    for (0..m) |rank| {
        const edge = order[rank];
        const source: usize = @intCast(edge_u[edge]);
        const target: usize = @intCast(edge_v[edge]);
        var distance = [_]i64{inf} ** max_n;
        var settled = [_]bool{false} ** max_n;
        distance[source] = 0;
        for (0..n) |_| {
            var vertex = n;
            for (0..n) |v| if (!settled[v] and (vertex == n or distance[v] < distance[vertex])) { vertex = v; };
            if (vertex == n or distance[vertex] == inf) break;
            settled[vertex] = true;
            for (0..n) |v| {
                const weight = adjacency[vertex][v];
                if (weight > 0 and distance[v] > distance[vertex] + weight) distance[v] = distance[vertex] + weight;
            }
        }
        if (distance[target] > (2 * k - 1) * edge_w[edge]) {
            selected[edge] = 1;
            adjacency[source][target] = edge_w[edge];
            adjacency[target][source] = edge_w[edge];
        }
    }
    @memcpy(output[0..m], selected[0..m]);
    return @intCast(m);
}
