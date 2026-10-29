const max_vertices = 16;
const max_edges = 64;
const max_input_length = 3 + 3 * max_edges;

fn storeI64Le(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| {
        output[offset + byte] = @truncate(bits >> @intCast(byte * 8));
    }
}

export fn d_esopo_pape(values: [*c]const i64, length: usize,
    output: [*c]u8, output_capacity: usize) i64 {
    if (values == null or length < 3 or length > max_input_length) return -1;
    const raw_n, const raw_m, const raw_source = .{ values[0], values[1], values[2] };
    if (raw_n < 1 or raw_n > max_vertices or raw_m < 0 or raw_m > max_edges or
        raw_source < 0 or raw_source >= raw_n or length != 3 + 3 * @as(usize, @intCast(raw_m))) return -1;
    const n: usize = @intCast(raw_n);
    const m: usize = @intCast(raw_m);

    var head: [max_vertices]i32 = @splat(-1);
    var to: [max_edges]i32 = @splat(0);
    var next: [max_edges]i32 = @splat(-1);
    var weight: [max_edges]i64 = @splat(0);
    for (0..m) |edge| {
        const u, const v, const w = .{ values[3 + 3 * edge], values[4 + 3 * edge], values[5 + 3 * edge] };
        if (u < 0 or u >= raw_n or v < 0 or v >= raw_n or w < 0 or w > 1000) return -1;
        const ui: usize = @intCast(u);
        to[edge] = @intCast(v);
        weight[edge] = w;
        next[edge] = head[ui];
        head[ui] = @intCast(edge);
    }

    var distance: [max_vertices]i64 = @splat(0);
    var reachable: [max_vertices]bool = @splat(false);
    var queued: [max_vertices]bool = @splat(false);
    var removed_before: [max_vertices]bool = @splat(false);
    var deque: [max_vertices]usize = @splat(0);
    var front: usize = 0;
    var size: usize = 1;
    const source: usize = @intCast(raw_source);
    deque[0] = source;
    distance[source] = 0;
    reachable[source] = true;
    queued[source] = true;
    while (size > 0) {
        const vertex = deque[front];
        front = (front + 1) % n;
        size -= 1;
        queued[vertex] = false;
        removed_before[vertex] = true;
        var edge = head[vertex];
        while (edge >= 0) {
            const edge_index: usize = @intCast(edge);
            const neighbor: usize = @intCast(to[edge_index]);
            const candidate = distance[vertex] + weight[edge_index];
            if (!reachable[neighbor] or candidate < distance[neighbor]) {
                distance[neighbor] = candidate;
                reachable[neighbor] = true;
                if (!queued[neighbor]) {
                    if (removed_before[neighbor]) {
                        front = (front + n - 1) % n;
                        deque[front] = neighbor;
                    } else {
                        deque[(front + size) % n] = neighbor;
                    }
                    size += 1;
                    queued[neighbor] = true;
                }
            }
            edge = next[edge_index];
        }
    }

    const byte_count = 8 * n;
    if (output == null or output_capacity < byte_count) return -2;
    for (0..n) |vertex| {
        storeI64Le(output, 8 * vertex, if (reachable[vertex]) distance[vertex] else -1);
    }
    return @intCast(byte_count);
}
