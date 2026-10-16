const MAX_VERTICES: usize = 64;
const MAX_INPUT_EDGES: usize = 256;
const MAX_NORMALIZED_EDGES: usize = 128;
const MAX_WEIGHT: i64 = 1_000;
const RECORD_BYTES: usize = 24;

fn writeRecord(output: [*c]u8, capacity: usize, status: i64, target_reachable: i64, distance: i64) i64 {
    if (output == null or capacity < RECORD_BYTES) return -2;
    const record = [3]i64{ status, target_reachable, distance };
    for (0..3) |field| {
        const bits: u64 = @bitCast(record[field]);
        for (0..8) |byte| output[field * 8 + byte] = @truncate(bits >> @intCast(byte * 8));
    }
    return @intCast(RECORD_BYTES);
}

export fn bellman_ford_pair(input: [*c]const i64, length: usize, output: [*c]u8, capacity: usize) i64 {
    if (input == null or length < 4) return -1;
    const vertices_value = input[0];
    const input_edges_value = input[1];
    const source_value = input[2];
    const target_value = input[3];
    if (vertices_value < 1 or vertices_value > @as(i64, @intCast(MAX_VERTICES)) or
        input_edges_value < 0 or input_edges_value > @as(i64, @intCast(MAX_INPUT_EDGES))) return -1;
    const vertices: usize = @intCast(vertices_value);
    const input_edges: usize = @intCast(input_edges_value);
    if (source_value < 0 or source_value >= vertices_value or target_value < 0 or target_value >= vertices_value or
        length != 4 + 3 * input_edges) return -1;

    var matrix_weights: [MAX_VERTICES * MAX_VERTICES]i64 = @splat(0);
    var matrix_present: [MAX_VERTICES * MAX_VERTICES]bool = @splat(false);
    var normalized_count: usize = 0;
    for (0..input_edges) |edge| {
        const from_value = input[4 + 3 * edge];
        const to_value = input[5 + 3 * edge];
        const weight_value = input[6 + 3 * edge];
        if (from_value < 0 or from_value >= vertices_value or to_value < 0 or to_value >= vertices_value or
            weight_value < -MAX_WEIGHT or weight_value > MAX_WEIGHT) return -1;
        const key: usize = @as(usize, @intCast(from_value)) * vertices + @as(usize, @intCast(to_value));
        if (!matrix_present[key]) {
            matrix_present[key] = true;
            normalized_count += 1;
            if (normalized_count > MAX_NORMALIZED_EDGES) return -1;
        }
        matrix_weights[key] = weight_value;
    }

    var from: [MAX_NORMALIZED_EDGES]usize = @splat(0);
    var to: [MAX_NORMALIZED_EDGES]usize = @splat(0);
    var weight: [MAX_NORMALIZED_EDGES]i64 = @splat(0);
    var edge_count: usize = 0;
    for (0..vertices) |origin| {
        for (0..vertices) |destination| {
            const key = origin * vertices + destination;
            if (!matrix_present[key]) continue;
            from[edge_count] = origin;
            to[edge_count] = destination;
            weight[edge_count] = matrix_weights[key];
            edge_count += 1;
        }
    }

    const source: usize = @intCast(source_value);
    const target: usize = @intCast(target_value);
    var distance: [MAX_VERTICES]i64 = @splat(0);
    var reachable: [MAX_VERTICES]bool = @splat(false);
    reachable[source] = true;
    for (0..vertices) |_| {
        var changed = false;
        for (0..edge_count) |edge| {
            if (!reachable[from[edge]]) continue;
            const candidate = distance[from[edge]] + weight[edge];
            if (!reachable[to[edge]] or candidate < distance[to[edge]]) {
                distance[to[edge]] = candidate;
                reachable[to[edge]] = true;
                changed = true;
            }
        }
        if (!changed) break;
    }
    for (0..edge_count) |edge| {
        if (reachable[from[edge]] and distance[to[edge]] > distance[from[edge]] + weight[edge])
            return writeRecord(output, capacity, -1, 0, 0);
    }
    return writeRecord(output, capacity, 0, if (reachable[target]) 1 else 0,
        if (reachable[target]) distance[target] else 0);
}
