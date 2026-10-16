const max_nodes: usize = 64;
const max_edges: usize = 94;
const max_input_length: usize = 4 + max_nodes + 2 * max_edges;
const max_output_bytes: usize = 128;

export fn depth_first_search_target_route(values: [*c]const i64, length: usize, output: [*c]u8, output_capacity: usize) i64 {
    if (values == null or length < 5 or length > max_input_length) return -2;
    if (values[0] < 1 or values[0] > @as(i64, @intCast(max_nodes))
        or values[1] < 0 or values[1] > 255 or values[2] < 0 or values[2] > 255) return -2;
    const node_count: usize = @intCast(values[0]);
    const start_label = values[1];
    const target_label = values[2];
    const edge_count_position = 3 + node_count;
    if (edge_count_position >= length) return -2;

    var labels: [max_nodes]i64 = @splat(0);
    var start_index: usize = node_count;
    for (0..node_count) |index| {
        const label = values[3 + index];
        if (label < 0 or label > 255) return -2;
        for (0..index) |prior| {
            if (labels[prior] == label) return -2;
        }
        labels[index] = label;
        if (label == start_label) start_index = index;
    }
    if (start_index == node_count) return -2;

    const edge_count_value = values[edge_count_position];
    if (edge_count_value < 0 or edge_count_value > @as(i64, @intCast(max_edges))) return -2;
    const edge_count: usize = @intCast(edge_count_value);
    if (length != edge_count_position + 1 + 2 * edge_count) return -2;

    var adjacency: [max_nodes]u64 = @splat(0);
    for (0..edge_count) |edge| {
        const left_label = values[edge_count_position + 1 + 2 * edge];
        const right_label = values[edge_count_position + 2 + 2 * edge];
        var left: usize = node_count;
        var right: usize = node_count;
        for (0..node_count) |index| {
            if (labels[index] == left_label) left = index;
            if (labels[index] == right_label) right = index;
        }
        if (left == node_count or right == node_count) return -2;
        adjacency[left] |= @as(u64, 1) << @intCast(right);
        adjacency[right] |= @as(u64, 1) << @intCast(left);
    }

    var stack: [max_nodes]usize = @splat(0);
    var stack_length: usize = 1;
    stack[0] = start_index;
    var route: [max_output_bytes]u8 = @splat(0);
    var route_length: usize = 0;
    while (stack_length != 0) {
        stack_length -= 1;
        const current = stack[stack_length];
        if (route_length == max_output_bytes) return -2;
        route[route_length] = @intCast(labels[current]);
        route_length += 1;
        for (0..node_count) |neighbor| {
            const bit = @as(u64, 1) << @intCast(neighbor);
            if ((adjacency[current] & bit) != 0) {
                var pending: usize = 0;
                while (pending < stack_length and stack[pending] != neighbor) : (pending += 1) {}
                if (pending == stack_length) {
                    stack[stack_length] = neighbor;
                    stack_length += 1;
                }
            }
            adjacency[current] &= ~bit;
            adjacency[neighbor] &= ~(@as(u64, 1) << @intCast(current));
        }
        if (labels[current] == target_label) {
            if (output_capacity < route_length or (route_length != 0 and output == null)) return -2;
            for (0..route_length) |index| output[index] = route[index];
            return @intCast(route_length);
        }
    }
    return 0;
}
