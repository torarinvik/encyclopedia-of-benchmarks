const MAX_VERTICES: usize = 8;
const MAX_EDGES: usize = 24;
const MAX_INPUT_VALUES: usize = 4 + 3 * MAX_EDGES + 1;
const FLOW_INFINITY: i64 = 2401;

fn minimum(a: i64, b: i64) i64 { return if (a < b) a else b; }

fn pushForward(vertex: usize, sink: usize, amount: i64, n: usize,
    residual: *[MAX_VERTICES][MAX_VERTICES]i64,
    active: *[MAX_VERTICES][MAX_VERTICES]bool,
    incoming: *[MAX_VERTICES]i64, outgoing: *[MAX_VERTICES]i64) i64 {
    if (vertex == sink) return amount;
    var remaining = amount;
    for (0..n) |next| {
        if (remaining == 0 or !active[vertex][next] or residual[vertex][next] == 0) continue;
        const pushed = pushForward(next, sink, minimum(remaining, residual[vertex][next]), n,
            residual, active, incoming, outgoing);
        if (pushed == 0) continue;
        residual[vertex][next] -= pushed;
        residual[next][vertex] += pushed;
        outgoing[vertex] -= pushed;
        incoming[next] -= pushed;
        remaining -= pushed;
        if (residual[vertex][next] == 0) active[vertex][next] = false;
    }
    return amount - remaining;
}

fn pushBackward(vertex: usize, source: usize, amount: i64, n: usize,
    residual: *[MAX_VERTICES][MAX_VERTICES]i64,
    active: *[MAX_VERTICES][MAX_VERTICES]bool,
    incoming: *[MAX_VERTICES]i64, outgoing: *[MAX_VERTICES]i64) i64 {
    if (vertex == source) return amount;
    var remaining = amount;
    for (0..n) |previous| {
        if (remaining == 0 or !active[previous][vertex] or residual[previous][vertex] == 0) continue;
        const pushed = pushBackward(previous, source, minimum(remaining, residual[previous][vertex]), n,
            residual, active, incoming, outgoing);
        if (pushed == 0) continue;
        residual[previous][vertex] -= pushed;
        residual[vertex][previous] += pushed;
        incoming[vertex] -= pushed;
        outgoing[previous] -= pushed;
        remaining -= pushed;
        if (residual[previous][vertex] == 0) active[previous][vertex] = false;
    }
    return amount - remaining;
}

fn removeVertex(vertex: usize, n: usize, residual: *[MAX_VERTICES][MAX_VERTICES]i64,
    active: *[MAX_VERTICES][MAX_VERTICES]bool, incoming: *[MAX_VERTICES]i64,
    outgoing: *[MAX_VERTICES]i64, alive: *[MAX_VERTICES]bool) void {
    for (0..n) |other| {
        if (active[other][vertex]) {
            const capacity = residual[other][vertex];
            outgoing[other] -= capacity;
            incoming[vertex] -= capacity;
            active[other][vertex] = false;
        }
        if (active[vertex][other]) {
            const capacity = residual[vertex][other];
            outgoing[vertex] -= capacity;
            incoming[other] -= capacity;
            active[vertex][other] = false;
        }
    }
    alive[vertex] = false;
}

export fn mpm_maxflow(values: ?[*]const i64, length: usize) i64 {
    if (values == null or length < 4 or length > MAX_INPUT_VALUES) return -1;
    const input = values.?;
    const n_value = input[0];
    const edge_count_value = input[1];
    const source_value = input[2];
    const sink_value = input[3];
    if (n_value < 2 or n_value > @as(i64, @intCast(MAX_VERTICES)) or edge_count_value < 0 or
        edge_count_value > @as(i64, @intCast(MAX_EDGES)) or source_value < 1 or source_value > n_value or
        sink_value < 1 or sink_value > n_value or source_value == sink_value) return -1;
    const n: usize = @intCast(n_value);
    const edge_count: usize = @intCast(edge_count_value);
    const source: usize = @intCast(source_value - 1);
    const sink: usize = @intCast(sink_value - 1);
    if (length != 4 + 3 * edge_count) return -1;

    var residual: [MAX_VERTICES][MAX_VERTICES]i64 = .{.{0} ** MAX_VERTICES} ** MAX_VERTICES;
    for (0..edge_count) |edge| {
        const from_value = input[4 + 3 * edge];
        const to_value = input[5 + 3 * edge];
        const capacity = input[6 + 3 * edge];
        if (from_value < 1 or from_value > n_value or to_value < 1 or to_value > n_value or
            from_value == to_value or capacity < 0 or capacity > 100) return -1;
        residual[@intCast(from_value - 1)][@intCast(to_value - 1)] += capacity;
    }

    var total_flow: i64 = 0;
    while (true) {
        var level = [_]i32{-1} ** MAX_VERTICES;
        var queue: [MAX_VERTICES]usize = undefined;
        var head: usize = 0;
        var tail: usize = 0;
        level[source] = 0;
        queue[tail] = source;
        tail += 1;
        while (head < tail) {
            const vertex = queue[head];
            head += 1;
            for (0..n) |next| {
                if (residual[vertex][next] > 0 and level[next] < 0) {
                    level[next] = level[vertex] + 1;
                    queue[tail] = next;
                    tail += 1;
                }
            }
        }
        if (level[sink] < 0) break;

        var incoming = [_]i64{0} ** MAX_VERTICES;
        var outgoing = [_]i64{0} ** MAX_VERTICES;
        var active = [_][MAX_VERTICES]bool{[_]bool{false} ** MAX_VERTICES} ** MAX_VERTICES;
        var alive = [_]bool{false} ** MAX_VERTICES;
        for (0..n) |vertex| alive[vertex] = level[vertex] >= 0 and level[vertex] <= level[sink];
        for (0..n) |from| {
            for (0..n) |to| {
                if (level[from] >= 0 and level[from] < level[sink] and
                    level[to] == level[from] + 1 and residual[from][to] > 0) {
                    active[from][to] = true;
                    outgoing[from] += residual[from][to];
                    incoming[to] += residual[from][to];
                }
            }
        }
        incoming[source] = FLOW_INFINITY;
        outgoing[sink] = FLOW_INFINITY;

        while (true) {
            var reference: ?usize = null;
            var least_potential = FLOW_INFINITY + 1;
            for (0..n) |vertex| {
                if (!alive[vertex]) continue;
                const potential = minimum(incoming[vertex], outgoing[vertex]);
                if (potential < least_potential) {
                    least_potential = potential;
                    reference = vertex;
                }
            }
            const chosen = reference orelse break;
            if (least_potential > 0) {
                total_flow += least_potential;
                _ = pushBackward(chosen, source, least_potential, n, &residual, &active, &incoming, &outgoing);
                _ = pushForward(chosen, sink, least_potential, n, &residual, &active, &incoming, &outgoing);
            }
            removeVertex(chosen, n, &residual, &active, &incoming, &outgoing, &alive);
        }
    }
    return total_flow;
}
