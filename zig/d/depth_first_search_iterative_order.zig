const MAX_VERTICES: usize = 10;
const MAX_EDGES: usize = 64;
const MAX_DEGREE: usize = 128;

fn putI64Le(output: [*c]u8, word: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[word * 8 + byte] = @truncate(bits >> @intCast(byte * 8));
}

export fn depth_first_search_iterative_order(input: [*c]const i64, length: usize,
    output: [*c]u8, capacity: usize) i64 {
    if (input == null or length < 3) return -1;
    const node_count_value, const edge_count_value = .{ input[0], input[1] };
    if (node_count_value < 1 or node_count_value > MAX_VERTICES or
        edge_count_value < 0 or edge_count_value > MAX_EDGES) return -1;
    const node_count: usize = @intCast(node_count_value);
    const edge_count: usize = @intCast(edge_count_value);
    if (length != 3 + 2 * edge_count) return -1;

    var adjacency: [11 * MAX_DEGREE]usize = @splat(0);
    var degree: [11]usize = @splat(0);
    var position: usize = 2;
    for (0..edge_count) |_| {
        const left_value, const right_value = .{ input[position], input[position + 1] };
        position += 2;
        if (left_value < 1 or left_value > node_count_value or
            right_value < 1 or right_value > node_count_value) return -1;
        const left: usize = @intCast(left_value);
        const right: usize = @intCast(right_value);
        adjacency[left * MAX_DEGREE + degree[left]] = right;
        degree[left] += 1;
        adjacency[right * MAX_DEGREE + degree[right]] = left;
        degree[right] += 1;
    }
    const start_value = input[position];
    if (start_value < 1 or start_value > node_count_value) return -1;
    const start: usize = @intCast(start_value);
    var visited: [11]bool = @splat(false);
    var stack: [MAX_VERTICES]usize = @splat(0);
    var order: [MAX_VERTICES]usize = @splat(0);
    visited[start] = true;
    var stack_size: usize = 1;
    var order_count: usize = 0;
    stack[0] = start;
    while (stack_size > 0) {
        stack_size -= 1;
        const vertex = stack[stack_size];
        order[order_count] = vertex;
        order_count += 1;
        for (0..degree[vertex]) |edge| {
            const neighbor = adjacency[vertex * MAX_DEGREE + edge];
            if (!visited[neighbor]) {
                visited[neighbor] = true;
                stack[stack_size] = neighbor;
                stack_size += 1;
            }
        }
    }

    const words = order_count + 1;
    if (output == null or capacity < words * 8) return -2;
    putI64Le(output, 0, @intCast(order_count));
    for (0..order_count) |index| putI64Le(output, index + 1, @intCast(order[index]));
    return @intCast(words * 8);
}
