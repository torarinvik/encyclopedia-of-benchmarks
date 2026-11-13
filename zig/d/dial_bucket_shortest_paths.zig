const max_n: usize = 16;
const max_m: usize = 64;
const max_records: usize = max_m + 1;
const max_distance: i64 = 120;
const bucket_count: usize = 9;
const max_input: usize = 196;
const max_output: usize = 128;

fn putI64Le(output: *[max_output]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn dial_bucket_shortest_paths(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 3 or length > max_input) return -1;
    const input = input_opt.?;
    const n64 = input[0];
    const m64 = input[1];
    const source64 = input[2];
    if (n64 < 1 or n64 > @as(i64, @intCast(max_n)) or m64 < 0 or
        m64 > @as(i64, @intCast(max_m)) or
        source64 < 0 or source64 >= n64) return -1;
    const n: usize = @intCast(n64);
    const m: usize = @intCast(m64);
    const source: usize = @intCast(source64);
    if (length != 3 + 3 * m) return -1;

    var edge_to: [max_m]usize = @splat(0);
    var edge_next: [max_m]usize = @splat(0);
    var edge_weight: [max_m]i64 = @splat(0);
    var edge_head: [max_n]usize = @splat(max_m);
    for (0..m) |edge| {
        const u = input[3 + 3 * edge];
        const v = input[4 + 3 * edge];
        const w = input[5 + 3 * edge];
        if (u < 0 or u >= n64 or v < 0 or v >= n64 or w < 0 or w > 8) return -1;
        const from: usize = @intCast(u);
        edge_to[edge] = @intCast(v);
        edge_weight[edge] = w;
        edge_next[edge] = edge_head[from];
        edge_head[from] = edge;
    }
    const needed = 8 * n;
    if (output_opt == null or capacity < needed) return -2;
    const output = output_opt.?;

    var distance: [max_n]i64 = @splat(max_distance + 1);
    var settled: [max_n]bool = @splat(false);
    distance[source] = 0;
    var bucket_head: [bucket_count]usize = @splat(max_records);
    var bucket_tail: [bucket_count]usize = @splat(max_records);
    var record_vertex: [max_records]usize = @splat(0);
    var record_next: [max_records]usize = @splat(max_records);
    var record_distance: [max_records]i64 = @splat(0);
    var used: usize = 1;
    record_vertex[0] = source;
    record_distance[0] = 0;
    bucket_head[0] = 0;
    bucket_tail[0] = 0;
    for (0..@as(usize, @intCast(max_distance + 1))) |current| {
        const bucket = current % bucket_count;
        while (bucket_head[bucket] != max_records) {
            const record = bucket_head[bucket];
            bucket_head[bucket] = record_next[record];
            if (bucket_head[bucket] == max_records) bucket_tail[bucket] = max_records;
            const u = record_vertex[record];
            if (record_distance[record] != @as(i64, @intCast(current)) or settled[u] or
                distance[u] != @as(i64, @intCast(current))) continue;
            settled[u] = true;
            var edge = edge_head[u];
            while (edge != max_m) : (edge = edge_next[edge]) {
                const v = edge_to[edge];
                const candidate = @as(i64, @intCast(current)) + edge_weight[edge];
                if (!settled[v] and candidate < distance[v]) {
                    if (used >= max_records) return -1;
                    distance[v] = candidate;
                    const destination: usize = @intCast(@mod(candidate, @as(i64, @intCast(bucket_count))));
                    record_vertex[used] = v;
                    record_distance[used] = candidate;
                    record_next[used] = max_records;
                    if (bucket_tail[destination] == max_records) bucket_head[destination] = used
                    else record_next[bucket_tail[destination]] = used;
                    bucket_tail[destination] = used;
                    used += 1;
                }
            }
        }
    }
    var staged: [max_output]u8 = @splat(0);
    for (0..n) |vertex| putI64Le(&staged, 8 * vertex,
        if (distance[vertex] > max_distance) -1 else distance[vertex]);
    @memcpy(output[0..needed], staged[0..needed]);
    return @intCast(needed);
}

