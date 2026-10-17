const MAX_VERTICES: usize = 32;
const MAX_EDGES: usize = 128;
const MAX_INPUT_LENGTH: usize = 257;

export fn kahns_algorithm(
    input: ?[*]const i64,
    length: usize,
    output: ?[*]u8,
    capacity: usize,
) i64 {
    if (input == null or length < 1 or length > MAX_INPUT_LENGTH) return -1;
    const input_ptr = input.?;
    const edge_count_value = input_ptr[0];
    if (edge_count_value < 0 or edge_count_value > MAX_EDGES) return -1;
    const edge_count: usize = @intCast(edge_count_value);
    if (length != 1 + 2 * edge_count) return -1;

    var labels: [MAX_VERTICES]i32 = undefined;
    var first_edge: [MAX_VERTICES]i32 = @splat(-1);
    var last_edge: [MAX_VERTICES]i32 = @splat(-1);
    var next_edge: [MAX_EDGES]i32 = @splat(-1);
    var to_by_edge: [MAX_EDGES]usize = undefined;
    var indegree: [MAX_VERTICES]usize = @splat(0);
    var vertex_count: usize = 0;
    for (0..edge_count) |edge| {
        const from_value = input_ptr[1 + 2 * edge];
        const to_value = input_ptr[2 + 2 * edge];
        if (from_value < -2147483648 or from_value > 2147483647 or
            to_value < -2147483648 or to_value > 2147483647) return -1;
        const from_label: i32 = @intCast(from_value);
        const to_label: i32 = @intCast(to_value);
        if (from_label == to_label) return -1;
        var from_index: ?usize = null;
        var to_index: ?usize = null;
        for (0..vertex_count) |i| {
            if (labels[i] == from_label) from_index = i;
            if (labels[i] == to_label) to_index = i;
        }
        if (from_index == null) {
            if (vertex_count >= MAX_VERTICES) return -1;
            from_index = vertex_count;
            labels[vertex_count] = from_label;
            vertex_count += 1;
        }
        if (to_index == null) {
            if (vertex_count >= MAX_VERTICES) return -1;
            to_index = vertex_count;
            labels[vertex_count] = to_label;
            vertex_count += 1;
        }
        to_by_edge[edge] = to_index.?;
        if (first_edge[from_index.?] < 0) {
            first_edge[from_index.?] = @intCast(edge);
        } else {
            next_edge[@intCast(last_edge[from_index.?])] = @intCast(edge);
        }
        last_edge[from_index.?] = @intCast(edge);
        indegree[to_index.?] += 1;
    }

    var queue: [MAX_VERTICES]usize = undefined;
    var order: [MAX_VERTICES]usize = undefined;
    var queue_head: usize = 0;
    var queue_tail: usize = 0;
    var order_count: usize = 0;
    for (0..vertex_count) |vertex| {
        if (indegree[vertex] == 0) {
            queue[queue_tail] = vertex;
            queue_tail += 1;
        }
    }
    if (vertex_count > 0 and queue_tail != 1) return -1;
    while (queue_head < queue_tail) {
        if (queue_tail - queue_head != 1) return -1;
        const current = queue[queue_head];
        queue_head += 1;
        order[order_count] = current;
        order_count += 1;
        var outgoing = first_edge[current];
        while (outgoing >= 0) {
            const edge: usize = @intCast(outgoing);
            const adjacent = to_by_edge[edge];
            if (indegree[adjacent] == 0) return -1;
            indegree[adjacent] -= 1;
            if (indegree[adjacent] == 0) {
                queue[queue_tail] = adjacent;
                queue_tail += 1;
            }
            outgoing = next_edge[edge];
        }
    }
    if (order_count != vertex_count) return -1;

    const output_bytes = 4 * order_count;
    if (output == null or capacity < output_bytes) return -2;
    const output_ptr = output.?;
    for (0..order_count) |i| {
        const bits: u32 = @bitCast(labels[order[i]]);
        for (0..4) |byte| output_ptr[4 * i + byte] = @truncate(bits >> @intCast(8 * byte));
    }
    return @intCast(output_bytes);
}
