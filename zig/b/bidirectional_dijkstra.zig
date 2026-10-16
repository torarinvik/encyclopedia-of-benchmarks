const MAX_VERTICES: usize = 64;
const MAX_EDGES: usize = 256;
const MAX_WEIGHT: i64 = 1_000_000;
const INF: i64 = 1_000_000_000;

/// Return the shortest directed path distance using two Dijkstra frontiers.
export fn bidirectional_dijkstra(input: [*c]const i64, length: usize) i64 {
    if (input == null or length < 4) return -1;
    const nv = input[0];
    const mv = input[1];
    const source_value = input[2];
    const target_value = input[3];
    if (nv < 1 or nv > @as(i64, @intCast(MAX_VERTICES)) or mv < 0 or mv > @as(i64, @intCast(MAX_EDGES))) return -1;
    if (source_value < 0 or source_value >= nv or target_value < 0 or target_value >= nv) return -1;
    const n: usize = @intCast(nv);
    const m: usize = @intCast(mv);
    if (length != 4 + 3 * m) return -1;
    for (0..m) |edge| {
        const from = input[4 + 3 * edge];
        const to = input[5 + 3 * edge];
        const weight = input[6 + 3 * edge];
        if (from < 0 or from >= nv or to < 0 or to >= nv or weight < 0 or weight > MAX_WEIGHT) return -1;
    }
    const source: usize = @intCast(source_value);
    const target: usize = @intCast(target_value);
    if (source == target) return 0;

    var forward: [MAX_VERTICES]i64 = @splat(INF);
    var backward: [MAX_VERTICES]i64 = @splat(INF);
    var settled_forward: [MAX_VERTICES]bool = @splat(false);
    var settled_backward: [MAX_VERTICES]bool = @splat(false);
    forward[source] = 0;
    backward[target] = 0;
    var best: i64 = INF;

    for (0..(2 * n)) |_| {
        var next_forward = n;
        var next_backward = n;
        var min_forward: i64 = INF;
        var min_backward: i64 = INF;
        for (0..n) |vertex| {
            if (!settled_forward[vertex] and forward[vertex] < min_forward) {
                min_forward = forward[vertex];
                next_forward = vertex;
            }
            if (!settled_backward[vertex] and backward[vertex] < min_backward) {
                min_backward = backward[vertex];
                next_backward = vertex;
            }
        }
        if (next_forward == n or next_backward == n) break;
        if (best != INF and min_forward + min_backward >= best) break;

        if (min_forward <= min_backward) {
            const current = next_forward;
            settled_forward[current] = true;
            if (backward[current] != INF and forward[current] + backward[current] < best) {
                best = forward[current] + backward[current];
            }
            for (0..m) |edge| {
                if (@as(usize, @intCast(input[4 + 3 * edge])) != current) continue;
                const to: usize = @intCast(input[5 + 3 * edge]);
                const candidate = forward[current] + input[6 + 3 * edge];
                if (!settled_forward[to] and candidate < forward[to]) forward[to] = candidate;
                if (backward[to] != INF and candidate + backward[to] < best) best = candidate + backward[to];
            }
        } else {
            const current = next_backward;
            settled_backward[current] = true;
            if (forward[current] != INF and forward[current] + backward[current] < best) {
                best = forward[current] + backward[current];
            }
            for (0..m) |edge| {
                if (@as(usize, @intCast(input[5 + 3 * edge])) != current) continue;
                const from: usize = @intCast(input[4 + 3 * edge]);
                const candidate = backward[current] + input[6 + 3 * edge];
                if (!settled_backward[from] and candidate < backward[from]) backward[from] = candidate;
                if (forward[from] != INF) {
                    const through_edge = forward[from] + input[6 + 3 * edge] + backward[current];
                    if (through_edge < best) best = through_edge;
                }
            }
        }
    }
    if (best == INF) return -1;
    return best;
}
