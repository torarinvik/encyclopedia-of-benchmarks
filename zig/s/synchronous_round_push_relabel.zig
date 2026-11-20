const MAX_VERTICES: usize = 8;
const MAX_ARCS: i64 = 24;
const MAX_INPUT_LENGTH: usize = 77;
const MAX_CAPACITY: i64 = 15;

export fn synchronous_round_push_relabel(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length < 4 or length > MAX_INPUT_LENGTH) return -1;
    const input = input_opt.?;
    const raw_n = input[0];
    const raw_m = input[1];
    const raw_source = input[2];
    const raw_sink = input[3];
    if (raw_n < 2 or raw_n > MAX_VERTICES or raw_m < 0 or raw_m > MAX_ARCS or
        raw_source < 0 or raw_source >= raw_n or raw_sink < 0 or raw_sink >= raw_n or
        raw_source == raw_sink) return -1;
    const n: usize = @intCast(raw_n);
    const m: usize = @intCast(raw_m);
    const source: usize = @intCast(raw_source);
    const sink: usize = @intCast(raw_sink);
    if (length != 4 + 3 * m) return -1;

    var capacity: [64]i64 = @splat(0);
    for (0..m) |index| {
        const offset = 4 + 3 * index;
        const u = input[offset];
        const v = input[offset + 1];
        const amount = input[offset + 2];
        if (u < 0 or u >= raw_n or v < 0 or v >= raw_n or u == v or
            amount < 0 or amount > MAX_CAPACITY) return -1;
        capacity[@as(usize, @intCast(u)) * MAX_VERTICES + @as(usize, @intCast(v))] += amount;
    }

    var residual = capacity;
    var excess: [MAX_VERTICES]i64 = @splat(0);
    var height: [MAX_VERTICES]usize = @splat(0);
    height[source] = n;
    for (0..n) |vertex| {
        if (vertex == source) continue;
        const forward = source * MAX_VERTICES + vertex;
        const reverse = vertex * MAX_VERTICES + source;
        const amount = residual[forward];
        if (amount != 0) {
            residual[forward] = 0;
            residual[reverse] += amount;
            excess[source] -= amount;
            excess[vertex] += amount;
        }
    }

    while (true) {
        var active: [MAX_VERTICES]usize = @splat(0);
        var active_count: usize = 0;
        for (0..n) |vertex| {
            if (vertex != source and vertex != sink and excess[vertex] > 0 and height[vertex] < n) {
                active[active_count] = vertex;
                active_count += 1;
            }
        }
        if (active_count == 0) return excess[sink];

        var change: [MAX_VERTICES]i64 = @splat(0);
        for (0..active_count) |active_index| {
            const u = active[active_index];
            var remaining = excess[u];
            for (0..n) |neighbor| {
                if (remaining <= 0) break;
                const forward = u * MAX_VERTICES + neighbor;
                const reverse = neighbor * MAX_VERTICES + u;
                if (residual[forward] > 0 and height[u] == height[neighbor] + 1) {
                    const amount = @min(remaining, residual[forward]);
                    residual[forward] -= amount;
                    residual[reverse] += amount;
                    change[u] -= amount;
                    change[neighbor] += amount;
                    remaining -= amount;
                }
            }
        }

        var next_excess = excess;
        var next_height = height;
        for (0..n) |vertex| next_excess[vertex] += change[vertex];
        for (0..active_count) |active_index| {
            const u = active[active_index];
            if (next_excess[u] <= 0) continue;
            var minimum = 2 * MAX_VERTICES + 1;
            for (0..n) |neighbor| {
                if (residual[u * MAX_VERTICES + neighbor] > 0 and height[neighbor] < minimum)
                    minimum = height[neighbor];
            }
            next_height[u] = if (minimum == 2 * MAX_VERTICES + 1) n + 1 else minimum + 1;
        }
        excess = next_excess;
        height = next_height;
    }
}
