// Clean-room bounded GAPBS delta-stepping profile; see package LICENSE.txt.
const max_n: usize = 16;
const max_m: usize = 64;
const max_input: usize = 4 + 3 * max_m;
const max_buckets: usize = 481;
const max_events: usize = 8192;
const inf_distance: i64 = 1_073_741_823;

fn appendEvent(bucket: usize, vertex: usize, heads: *[max_buckets]i32,
    tails: *[max_buckets]i32, event_vertex: *[max_events]i32,
    event_next: *[max_events]i32, used: *usize) bool {
    if (bucket >= max_buckets or used.* >= max_events) return false;
    const event: i32 = @intCast(used.*);
    used.* += 1;
    event_vertex[@intCast(event)] = @intCast(vertex);
    event_next[@intCast(event)] = -1;
    if (heads[bucket] < 0) heads[bucket] = event else event_next[@intCast(tails[bucket])] = event;
    tails[bucket] = event;
    return true;
}

fn storeI64LE(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn gapbs_delta_step_sssp(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 4 or length > max_input) return -1;
    const input = input_opt.?;
    const n64 = input[0];
    const m64 = input[1];
    const source64 = input[2];
    const delta64 = input[3];
    if (n64 < 1 or n64 > 16 or m64 < 0 or m64 > 64 or source64 < 0 or source64 >= n64
        or delta64 < 1 or delta64 > 16 or length != 4 + 3 * @as(usize, @intCast(m64))) return -1;
    const n: usize = @intCast(n64);
    const m: usize = @intCast(m64);
    const source: usize = @intCast(source64);
    const delta: i64 = delta64;
    var edge_from: [max_m]usize = [_]usize{0} ** max_m;
    var edge_to: [max_m]usize = [_]usize{0} ** max_m;
    var edge_weight: [max_m]i64 = [_]i64{0} ** max_m;
    for (0..m) |edge| {
        const from = input[4 + 3 * edge];
        const to = input[5 + 3 * edge];
        const weight = input[6 + 3 * edge];
        if (from < 0 or from >= n64 or to < 0 or to >= n64 or weight < 0 or weight > 32) return -1;
        edge_from[edge] = @intCast(from);
        edge_to[edge] = @intCast(to);
        edge_weight[edge] = weight;
    }
    const output_bytes = 8 * n;
    if (output_opt == null or capacity < output_bytes) return -2;
    const output = output_opt.?;

    var distance: [max_n]i64 = [_]i64{inf_distance} ** max_n;
    distance[source] = 0;
    var heads: [max_buckets]i32 = [_]i32{-1} ** max_buckets;
    var tails: [max_buckets]i32 = [_]i32{-1} ** max_buckets;
    var event_vertex: [max_events]i32 = [_]i32{0} ** max_events;
    var event_next: [max_events]i32 = [_]i32{-1} ** max_events;
    var used: usize = 0;
    if (!appendEvent(0, source, &heads, &tails, &event_vertex, &event_next, &used)) return -1;
    for (0..max_buckets) |bucket| {
        while (heads[bucket] >= 0) {
            const event: usize = @intCast(heads[bucket]);
            heads[bucket] = event_next[event];
            if (heads[bucket] < 0) tails[bucket] = -1;
            const u: usize = @intCast(event_vertex[event]);
            if (distance[u] < delta * @as(i64, @intCast(bucket))) continue;
            for (0..m) |edge| {
                if (edge_from[edge] != u) continue;
                const v = edge_to[edge];
                const candidate = distance[u] + edge_weight[edge];
                if (candidate < distance[v]) {
                    distance[v] = candidate;
                    const destination: usize = @intCast(@divTrunc(candidate, delta));
                    if (!appendEvent(destination, v, &heads, &tails, &event_vertex, &event_next, &used)) return -1;
                }
            }
        }
    }
    for (0..n) |vertex| storeI64LE(output, 8 * vertex, distance[vertex]);
    return @intCast(output_bytes);
}
