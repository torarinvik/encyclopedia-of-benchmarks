const MAX_N: usize = 8;
const MAX_ARCS: usize = 12;
const MAX_TRIPS: usize = 4;
const MAX_OUTPUT_BYTES: usize = 88;
const INF: i64 = 1_000_000_000;

fn store_i64_le(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn timetable_earliest_arrival_dijkstra(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 5 or length > 138) return -1;
    const input = input_opt.?;
    const n_raw = input[0];
    const arc_count_raw = input[1];
    const source_raw = input[2];
    const target_raw = input[3];
    const start_time = input[4];
    if (n_raw < 2 or n_raw > @as(i64, MAX_N) or arc_count_raw < 0 or arc_count_raw > @as(i64, MAX_ARCS) or
            source_raw < 0 or source_raw >= n_raw or target_raw < 0 or target_raw >= n_raw or start_time < 0 or start_time > 1000) return -1;
    const n: usize = @intCast(n_raw);
    const arc_count: usize = @intCast(arc_count_raw);
    const source: usize = @intCast(source_raw);
    const target: usize = @intCast(target_raw);
    var arc_u: [MAX_ARCS]usize = @splat(0);
    var arc_v: [MAX_ARCS]usize = @splat(0);
    var trip_count: [MAX_ARCS]usize = @splat(0);
    var departure: [MAX_ARCS][MAX_TRIPS]i64 = @splat(@splat(0));
    var arrival: [MAX_ARCS][MAX_TRIPS]i64 = @splat(@splat(0));
    var cursor: usize = 5;
    for (0..arc_count) |edge| {
        if (cursor + 3 > length) return -1;
        const u_raw = input[cursor]; const v_raw = input[cursor + 1]; const count_raw = input[cursor + 2]; cursor += 3;
        if (u_raw < 0 or u_raw >= n_raw or v_raw < 0 or v_raw >= n_raw or u_raw == v_raw or count_raw < 1 or
                count_raw > @as(i64, MAX_TRIPS) or cursor + 2 * @as(usize, @intCast(count_raw)) > length) return -1;
        const u: usize = @intCast(u_raw);
        const v: usize = @intCast(v_raw);
        const count: usize = @intCast(count_raw);
        for (0..edge) |prior| if (arc_u[prior] == u and arc_v[prior] == v) return -1;
        arc_u[edge] = u; arc_v[edge] = v; trip_count[edge] = count;
        for (0..count) |trip| {
            const dep = input[cursor]; const arr = input[cursor + 1]; cursor += 2;
            if (dep < 0 or dep > 1000 or arr <= dep or arr > 2000 or
                    (trip > 0 and (dep <= departure[edge][trip - 1] or arr < arrival[edge][trip - 1]))) return -1;
            departure[edge][trip] = dep;
            arrival[edge][trip] = arr;
        }
    }
    if (cursor != length) return -1;

    var distance: [MAX_N]i64 = @splat(INF);
    var parent: [MAX_N]i32 = @splat(-1);
    var settled: [MAX_N]bool = @splat(false);
    distance[source] = start_time;
    for (0..n) |_| {
        var chosen = MAX_N;
        for (0..n) |vertex| {
            if (!settled[vertex] and distance[vertex] < INF and
                    (chosen == MAX_N or distance[vertex] < distance[chosen] or
                     (distance[vertex] == distance[chosen] and vertex < chosen))) chosen = vertex;
        }
        if (chosen == MAX_N) break;
        settled[chosen] = true;
        for (0..arc_count) |edge| {
            const v = arc_v[edge];
            if (arc_u[edge] != chosen or settled[v]) continue;
            var trip: usize = 0;
            while (trip < trip_count[edge] and departure[edge][trip] < distance[chosen]) : (trip += 1) {}
            if (trip == trip_count[edge]) continue;
            const candidate = arrival[edge][trip];
            if (candidate < distance[v] or (candidate == distance[v] and (parent[v] < 0 or chosen < @as(usize, @intCast(parent[v]))))) {
                distance[v] = candidate;
                parent[v] = @intCast(chosen);
            }
        }
    }

    var reverse_path: [MAX_N]usize = @splat(0);
    var path_length: usize = 0;
    if (distance[target] < INF) {
        var current = target;
        reverse_path[path_length] = current; path_length += 1;
        while (current != source and path_length < n) {
            if (parent[current] < 0) { path_length = 0; break; }
            current = @intCast(parent[current]);
            reverse_path[path_length] = current; path_length += 1;
        }
        if (path_length == 0 or reverse_path[path_length - 1] != source) path_length = 0;
    }
    const reachable = path_length > 0;
    const output_bytes = if (reachable) 8 * (3 + path_length) else 24;
    if (output_opt == null or capacity < output_bytes) return -2;
    const output = output_opt.?;
    var staged: [MAX_OUTPUT_BYTES]u8 = @splat(0);
    store_i64_le(&staged, 0, if (reachable) 1 else 0);
    store_i64_le(&staged, 8, if (reachable) distance[target] else -1);
    store_i64_le(&staged, 16, @intCast(path_length));
    if (reachable) {
        for (0..path_length) |i| store_i64_le(&staged, 24 + 8 * i, @intCast(reverse_path[path_length - 1 - i]));
    }
    for (0..output_bytes) |byte| output[byte] = staged[byte];
    return @intCast(output_bytes);
}
