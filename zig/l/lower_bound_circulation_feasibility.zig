const MAX_N: usize = 6;
const MAX_M: usize = 8;
const MAX_INPUT: usize = 35;
const NODE_CAP: usize = 8;

fn execute(input: []const i64) ?i64 {
    if (input.len < 2 or input.len > MAX_INPUT) return null;
    const n_value = input[0];
    const m_value = input[1];
    if (n_value < 1 or n_value > 6 or m_value < 0 or m_value > 8) return null;
    const n: usize = @intCast(n_value);
    const m: usize = @intCast(m_value);
    if (input.len != 2 + 4 * m) return null;

    var residual: [NODE_CAP * NODE_CAP]i64 = @splat(0);
    var balance: [MAX_N]i64 = @splat(0);
    for (0..m) |index| {
        const offset = 2 + 4 * index;
        const u_value = input[offset];
        const v_value = input[offset + 1];
        const lower = input[offset + 2];
        const upper = input[offset + 3];
        if (u_value < 0 or u_value >= n_value or v_value < 0 or v_value >= n_value
            or lower < 0 or upper < lower or upper > 2) return null;
        const u: usize = @intCast(u_value);
        const v: usize = @intCast(v_value);
        residual[u * NODE_CAP + v] += upper - lower;
        balance[u] -= lower;
        balance[v] += lower;
    }

    const source = n;
    const sink = n + 1;
    const node_count = n + 2;
    var demand: i64 = 0;
    for (0..n) |vertex| {
        if (balance[vertex] > 0) {
            residual[source * NODE_CAP + vertex] += balance[vertex];
            demand += balance[vertex];
        } else if (balance[vertex] < 0) {
            residual[vertex * NODE_CAP + sink] += -balance[vertex];
        }
    }

    var flow: i64 = 0;
    while (flow < demand) {
        var parent: [NODE_CAP]i32 = @splat(-1);
        var queue: [NODE_CAP]usize = @splat(0);
        var head: usize = 0;
        var tail: usize = 0;
        parent[source] = @intCast(source);
        queue[tail] = source;
        tail += 1;
        while (head < tail and parent[sink] < 0) {
            const u = queue[head];
            head += 1;
            for (0..node_count) |v| {
                if (residual[u * NODE_CAP + v] > 0 and parent[v] < 0) {
                    parent[v] = @intCast(u);
                    queue[tail] = v;
                    tail += 1;
                    if (v == sink) break;
                }
            }
        }
        if (parent[sink] < 0) break;
        var amount = demand - flow;
        var vertex = sink;
        while (vertex != source) {
            const u: usize = @intCast(parent[vertex]);
            amount = @min(amount, residual[u * NODE_CAP + vertex]);
            vertex = u;
        }
        vertex = sink;
        while (vertex != source) {
            const u: usize = @intCast(parent[vertex]);
            residual[u * NODE_CAP + vertex] -= amount;
            residual[vertex * NODE_CAP + u] += amount;
            vertex = u;
        }
        flow += amount;
    }
    return if (flow == demand) 1 else 0;
}

export fn lower_bound_circulation_feasibility(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length < 2 or length > MAX_INPUT) return -1;
    const input = input_opt.?[0..length];
    return execute(input) orelse -1;
}
