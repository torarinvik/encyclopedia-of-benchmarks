const MAX_VERTICES: usize = 26;
const MAX_EDGES: usize = 256;
const MAX_DEGREE: usize = 512;
const MAX_INPUT_LENGTH: usize = 541;
const MAX_OUTPUT_VALUES: usize = 645;
const MAX_QUEUE: usize = 513;

fn storeI64Le(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @intCast((bits >> @intCast(byte * 8)) & 0xff);
}

export fn graph_js_undirected_unweighted(values: ?[*]const i64, length: usize,
    output: ?[*]u8, output_capacity: usize) i64 {
    if (values == null or length < 4 or length > MAX_INPUT_LENGTH) return -1;
    const input = values.?[0..length];
    if (input[0] < 1 or input[0] > MAX_VERTICES) return -1;
    const vertex_count: usize = @intCast(input[0]);
    if (length < 1 + vertex_count + 2) return -1;

    var vertices: [MAX_VERTICES]usize = @splat(0);
    var declared: [MAX_VERTICES]bool = @splat(false);
    for (0..vertex_count) |index| {
        const value = input[1 + index];
        if (value < 97 or value > 122) return -1;
        const vertex: usize = @intCast(value - 97);
        if (declared[vertex]) return -1;
        declared[vertex] = true;
        vertices[index] = vertex;
    }
    const edge_count_offset = 1 + vertex_count;
    const raw_edge_count = input[edge_count_offset];
    if (raw_edge_count < 0 or raw_edge_count > MAX_EDGES) return -1;
    const edge_count: usize = @intCast(raw_edge_count);
    if (length != 1 + vertex_count + 1 + 2 * edge_count + 1) return -1;

    var adjacency: [MAX_VERTICES * MAX_DEGREE]u8 = @splat(0);
    var degree: [MAX_VERTICES]usize = @splat(0);
    var position = edge_count_offset + 1;
    for (0..edge_count) |_| {
        const left_value = input[position];
        const right_value = input[position + 1];
        position += 2;
        if (left_value < 97 or left_value > 122 or right_value < 97 or right_value > 122) return -1;
        const left: usize = @intCast(left_value - 97);
        const right: usize = @intCast(right_value - 97);
        if (declared[left] and declared[right]) {
            if (degree[left] >= MAX_DEGREE or degree[right] >= MAX_DEGREE) return -1;
            adjacency[left * MAX_DEGREE + degree[left]] = @intCast(right);
            degree[left] += 1;
            adjacency[right * MAX_DEGREE + degree[right]] = @intCast(left);
            degree[right] += 1;
        }
    }
    const start_value = input[position];
    if (start_value < 97 or start_value > 122) return -1;
    const start: usize = @intCast(start_value - 97);
    if (!declared[start]) return -1;

    var encoded_values: [MAX_OUTPUT_VALUES]i64 = @splat(0);
    var result_length: usize = 0;
    encoded_values[result_length] = @intCast(vertex_count);
    result_length += 1;
    for (0..vertex_count) |index| {
        const vertex = vertices[index];
        encoded_values[result_length] = @intCast(97 + vertex);
        encoded_values[result_length + 1] = @intCast(degree[vertex]);
        result_length += 2;
        for (0..degree[vertex]) |edge| {
            encoded_values[result_length] = @intCast(97 + adjacency[vertex * MAX_DEGREE + edge]);
            result_length += 1;
        }
    }

    var visited: [MAX_VERTICES]bool = @splat(false);
    var queue: [MAX_QUEUE]usize = @splat(0);
    var levels: [MAX_QUEUE]usize = @splat(0);
    const bfs_count_slot = result_length;
    result_length += 1;
    var head: usize = 0;
    var tail: usize = 1;
    queue[0] = start;
    levels[0] = 0;
    var bfs_count: usize = 0;
    while (head < tail) {
        const vertex = queue[head];
        const level = levels[head];
        head += 1;
        if (visited[vertex]) continue;
        visited[vertex] = true;
        encoded_values[result_length] = @intCast(97 + vertex);
        encoded_values[result_length + 1] = @intCast(level);
        result_length += 2;
        bfs_count += 1;
        for (0..degree[vertex]) |edge| {
            queue[tail] = adjacency[vertex * MAX_DEGREE + edge];
            levels[tail] = level + 1;
            tail += 1;
        }
    }
    encoded_values[bfs_count_slot] = @intCast(bfs_count);

    visited = @splat(false);
    const dfs_count_slot = result_length;
    result_length += 1;
    var stack_vertices: [MAX_VERTICES]usize = @splat(0);
    var stack_next_edge: [MAX_VERTICES]usize = @splat(0);
    var stack_depth: usize = 1;
    stack_vertices[0] = start;
    visited[start] = true;
    encoded_values[result_length] = @intCast(97 + start);
    result_length += 1;
    var dfs_count: usize = 1;
    while (stack_depth > 0) {
        const top = stack_depth - 1;
        const vertex = stack_vertices[top];
        if (stack_next_edge[top] >= degree[vertex]) {
            stack_depth -= 1;
            continue;
        }
        const edge = stack_next_edge[top];
        stack_next_edge[top] += 1;
        const neighbor = adjacency[vertex * MAX_DEGREE + edge];
        if (!visited[neighbor]) {
            visited[neighbor] = true;
            encoded_values[result_length] = @intCast(97 + neighbor);
            result_length += 1;
            dfs_count += 1;
            stack_vertices[stack_depth] = neighbor;
            stack_next_edge[stack_depth] = 0;
            stack_depth += 1;
        }
    }
    encoded_values[dfs_count_slot] = @intCast(dfs_count);

    const output_bytes = result_length * 8;
    if (output == null or output_capacity < output_bytes) return -2;
    const destination = output.?[0..output_bytes];
    for (0..result_length) |index| storeI64Le(destination.ptr, index * 8, encoded_values[index]);
    return @intCast(output_bytes);
}
