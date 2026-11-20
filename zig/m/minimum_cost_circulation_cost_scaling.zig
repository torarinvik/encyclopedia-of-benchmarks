const MAX_N: usize = 8;
const MAX_M: usize = 10;
const MAX_INPUT_LENGTH: usize = 43;
const MAX_ARCS: usize = 2 * MAX_M;
const COST_OFFSET: i64 = 81;

const ResidualArc = struct {
    from: usize = 0,
    to: usize = 0,
    reverse: usize = 0,
    capacity: i64 = 0,
    cost: i64 = 0,
};

fn execute(input: []const i64) ?i64 {
    if (input.len < 2 or input.len > MAX_INPUT_LENGTH) return null;
    const n_value = input[0];
    const m_value = input[1];
    if (n_value < 1 or n_value > 8 or m_value < 0 or m_value > 10) return null;
    const n: usize = @intCast(n_value);
    const m: usize = @intCast(m_value);
    if (input.len != 2 + 4 * m) return null;

    var edges: [MAX_ARCS]ResidualArc = @splat(.{});
    var max_scaled_cost: i64 = 0;
    for (0..m) |index| {
        const offset = 2 + 4 * index;
        const from_value = input[offset];
        const to_value = input[offset + 1];
        const capacity = input[offset + 2];
        const cost = input[offset + 3];
        if (from_value < 0 or from_value >= n_value or to_value < 0 or to_value >= n_value
            or capacity < 0 or capacity > 2 or cost < -4 or cost > 4) return null;
        const from: usize = @intCast(from_value);
        const to: usize = @intCast(to_value);
        const scaled_cost = cost * @as(i64, @intCast(n + 1));
        const forward = 2 * index;
        const reverse = forward + 1;
        edges[forward] = .{ .from = from, .to = to, .reverse = reverse, .capacity = capacity, .cost = scaled_cost };
        edges[reverse] = .{ .from = to, .to = from, .reverse = forward, .capacity = 0, .cost = -scaled_cost };
        const magnitude = if (scaled_cost < 0) -scaled_cost else scaled_cost;
        if (magnitude > max_scaled_cost) max_scaled_cost = magnitude;
    }

    var epsilon: i64 = 1;
    while (epsilon < max_scaled_cost) epsilon *= 2;
    var price: [MAX_N]i64 = @splat(0);
    const arc_count = 2 * m;
    while (epsilon > 1) {
        epsilon /= 2;
        var excess: [MAX_N]i64 = @splat(0);

        for (0..arc_count) |edge_index| {
            if (edges[edge_index].capacity <= 0) continue;
            const from = edges[edge_index].from;
            const to = edges[edge_index].to;
            const reduced_cost = edges[edge_index].cost + price[from] - price[to];
            if (reduced_cost < 0) {
                const amount = edges[edge_index].capacity;
                edges[edge_index].capacity = 0;
                edges[edges[edge_index].reverse].capacity += amount;
                excess[from] -= amount;
                excess[to] += amount;
            }
        }

        var queue: [MAX_N]usize = @splat(0);
        var queued: [MAX_N]bool = @splat(false);
        var head: usize = 0;
        var tail: usize = 0;
        var queue_count: usize = 0;
        for (0..n) |vertex| {
            if (excess[vertex] > 0) {
                queue[tail] = vertex;
                tail = (tail + 1) % n;
                queue_count += 1;
                queued[vertex] = true;
            }
        }

        while (queue_count > 0) {
            const vertex = queue[head];
            head = (head + 1) % n;
            queue_count -= 1;
            queued[vertex] = false;
            while (excess[vertex] > 0) {
                var admissible: ?usize = null;
                for (0..arc_count) |edge_index| {
                    const edge = edges[edge_index];
                    if (edge.from != vertex or edge.to == vertex or edge.capacity <= 0) continue;
                    if (edge.cost + price[vertex] - price[edge.to] < 0) {
                        admissible = edge_index;
                        break;
                    }
                }

                if (admissible) |edge_index| {
                    const to = edges[edge_index].to;
                    const reverse = edges[edge_index].reverse;
                    const amount = @min(excess[vertex], edges[edge_index].capacity);
                    edges[edge_index].capacity -= amount;
                    edges[reverse].capacity += amount;
                    const old_excess = excess[to];
                    excess[vertex] -= amount;
                    excess[to] += amount;
                    if (old_excess <= 0 and excess[to] > 0 and !queued[to]) {
                        queue[tail] = to;
                        tail = (tail + 1) % n;
                        queue_count += 1;
                        queued[to] = true;
                    }
                } else {
                    var best_price: ?i64 = null;
                    for (0..arc_count) |edge_index| {
                        const edge = edges[edge_index];
                        if (edge.from != vertex or edge.capacity <= 0) continue;
                        const candidate = price[edge.to] - edge.cost - epsilon;
                        if (best_price == null or candidate > best_price.?) best_price = candidate;
                    }
                    if (best_price == null) return null;
                    price[vertex] = best_price.?;
                }
            }
        }
        for (0..n) |vertex| {
            if (excess[vertex] != 0) return null;
        }
    }

    var total_cost: i64 = 0;
    for (0..m) |index| {
        const capacity = input[2 + 4 * index + 2];
        const cost = input[2 + 4 * index + 3];
        const flow = capacity - edges[2 * index].capacity;
        total_cost += flow * cost;
    }
    return total_cost + COST_OFFSET;
}

export fn minimum_cost_circulation_cost_scaling(input_opt: ?[*]const i64, length: usize) i64 {
    const input = input_opt orelse return -1;
    if (length < 2 or length > MAX_INPUT_LENGTH) return -1;
    return execute(input[0..length]) orelse -1;
}
