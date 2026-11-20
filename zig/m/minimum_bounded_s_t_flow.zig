const MAX_N: usize = 6;
const MAX_M: usize = 8;
const MAX_INPUT: usize = 37;
const NODE_CAP: usize = 8;

fn feasible(input: []const i64, n: usize, m: usize, source: usize,
    sink: usize, flow_cap: i64) bool {
    var residual: [NODE_CAP * NODE_CAP]i64 = @splat(0);
    var balance: [MAX_N]i64 = @splat(0);
    for (0..m) |index| {
        const offset = 4 + 4 * index;
        const u: usize = @intCast(input[offset]);
        const v: usize = @intCast(input[offset + 1]);
        const lower = input[offset + 2];
        const upper = input[offset + 3];
        residual[u * NODE_CAP + v] += upper - lower;
        balance[u] -= lower;
        balance[v] += lower;
    }
    residual[sink * NODE_CAP + source] += flow_cap;

    const super_source = n;
    const super_sink = n + 1;
    const node_count = n + 2;
    var demand: i64 = 0;
    for (0..n) |vertex| {
        if (balance[vertex] > 0) {
            residual[super_source * NODE_CAP + vertex] += balance[vertex];
            demand += balance[vertex];
        } else if (balance[vertex] < 0) {
            residual[vertex * NODE_CAP + super_sink] += -balance[vertex];
        }
    }

    var flow: i64 = 0;
    while (flow < demand) {
        var parent: [NODE_CAP]i32 = @splat(-1);
        var queue: [NODE_CAP]usize = @splat(0);
        var head: usize = 0;
        var tail: usize = 0;
        parent[super_source] = @intCast(super_source);
        queue[tail] = super_source;
        tail += 1;
        while (head < tail and parent[super_sink] < 0) {
            const u = queue[head];
            head += 1;
            for (0..node_count) |v| {
                if (residual[u * NODE_CAP + v] > 0 and parent[v] < 0) {
                    parent[v] = @intCast(u);
                    queue[tail] = v;
                    tail += 1;
                    if (v == super_sink) break;
                }
            }
        }
        if (parent[super_sink] < 0) break;
        var amount = demand - flow;
        var vertex = super_sink;
        while (vertex != super_source) {
            const u: usize = @intCast(parent[vertex]);
            amount = @min(amount, residual[u * NODE_CAP + vertex]);
            vertex = u;
        }
        vertex = super_sink;
        while (vertex != super_source) {
            const u: usize = @intCast(parent[vertex]);
            residual[u * NODE_CAP + vertex] -= amount;
            residual[vertex * NODE_CAP + u] += amount;
            vertex = u;
        }
        flow += amount;
    }
    return flow == demand;
}

fn execute(input: []const i64) ?i64 {
    if (input.len < 4 or input.len > MAX_INPUT) return null;
    const n_value = input[0];
    const m_value = input[1];
    const source_value = input[2];
    const sink_value = input[3];
    if (n_value < 2 or n_value > 6 or m_value < 0 or m_value > 8) return null;
    if (source_value < 0 or source_value >= n_value or sink_value < 0 or
        sink_value >= n_value or source_value == sink_value) return null;
    const n: usize = @intCast(n_value);
    const m: usize = @intCast(m_value);
    const source: usize = @intCast(source_value);
    const sink: usize = @intCast(sink_value);
    if (input.len != 4 + 4 * m) return null;

    var upper_bound: i64 = 0;
    for (0..m) |index| {
        const offset = 4 + 4 * index;
        const u = input[offset];
        const v = input[offset + 1];
        const lower = input[offset + 2];
        const upper = input[offset + 3];
        if (u < 0 or u >= n_value or v < 0 or v >= n_value or lower < 0 or
            upper < lower or upper > 2) return null;
        if (@as(usize, @intCast(u)) == source and @as(usize, @intCast(v)) != source) {
            upper_bound += upper;
        }
    }

    var low: i64 = 0;
    var high = upper_bound + 1;
    while (low < high) {
        const middle = low + (high - low) / 2;
        if (feasible(input, n, m, source, sink, middle)) {
            high = middle;
        } else {
            low = middle + 1;
        }
    }
    return if (low > upper_bound) -2 else low;
}

export fn minimum_bounded_s_t_flow(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length < 4 or length > MAX_INPUT) return -1;
    const input = input_opt.?[0..length];
    return execute(input) orelse -1;
}
