const MAX_VERTEX_COUNT: usize = 40;
const MAX_EDGE_COUNT: i64 = 2047;
const MAX_INPUT_LENGTH: usize = 2 + 2 * @as(usize, @intCast(MAX_EDGE_COUNT));

fn fillOrder(adjacency: *[MAX_VERTEX_COUNT]u64, visited: *[MAX_VERTEX_COUNT]bool,
    order: *[MAX_VERTEX_COUNT]usize, order_length: *usize, vertex_count: usize, vertex: usize) void {
    visited[vertex] = true;
    for (0..vertex_count) |neighbor| {
        if (adjacency[vertex] & (@as(u64, 1) << @intCast(neighbor)) != 0 and !visited[neighbor])
            fillOrder(adjacency, visited, order, order_length, vertex_count, neighbor);
    }
    order[order_length.*] = vertex;
    order_length.* += 1;
}

fn collectComponent(transpose: *[MAX_VERTEX_COUNT]u64, visited: *[MAX_VERTEX_COUNT]bool,
    component_id: *[MAX_VERTEX_COUNT]i64, vertex_count: usize, vertex: usize, id: i64) void {
    visited[vertex] = true;
    component_id[vertex] = id;
    for (0..vertex_count) |neighbor| {
        if (transpose[vertex] & (@as(u64, 1) << @intCast(neighbor)) != 0 and !visited[neighbor])
            collectComponent(transpose, visited, component_id, vertex_count, neighbor, id);
    }
}

fn encodeComponents(component_id: *[MAX_VERTEX_COUNT]i64, vertex_count: usize,
    component_count: usize, output: [*]u8, output_capacity: usize) i64 {
    const output_length = 1 + vertex_count + component_count;
    if (output_capacity < output_length) return -2;
    output[0] = @intCast(component_count);
    var position: usize = 1;
    for (0..vertex_count) |first| {
        const id = component_id[first];
        var emitted = false;
        for (0..first) |earlier| {
            if (component_id[earlier] == id) emitted = true;
        }
        if (emitted) continue;
        var component_size: usize = 0;
        for (first..vertex_count) |member| {
            if (component_id[member] == id) component_size += 1;
        }
        output[position] = @intCast(component_size);
        position += 1;
        for (first..vertex_count) |member| {
            if (component_id[member] == id) {
                output[position] = @intCast(member);
                position += 1;
            }
        }
    }
    return @intCast(output_length);
}

export fn kosaraju(input: [*]const i64, length: usize,
    output: [*]u8, output_capacity: usize) i64 {
    if (length < 2 or length > MAX_INPUT_LENGTH or input[0] < 0 or
        input[0] > @as(i64, @intCast(MAX_VERTEX_COUNT)) or input[1] < 0 or input[1] > MAX_EDGE_COUNT) return -1;
    const vertex_count: usize = @intCast(input[0]);
    const edge_count: usize = @intCast(input[1]);
    if (length != 2 + 2 * edge_count) return -1;
    var adjacency: [MAX_VERTEX_COUNT]u64 = [_]u64{0} ** MAX_VERTEX_COUNT;
    var transpose: [MAX_VERTEX_COUNT]u64 = [_]u64{0} ** MAX_VERTEX_COUNT;
    for (0..edge_count) |edge| {
        const from_value = input[2 + 2 * edge];
        const to_value = input[3 + 2 * edge];
        if (from_value < 0 or to_value < 0 or from_value >= @as(i64, @intCast(vertex_count)) or
            to_value >= @as(i64, @intCast(vertex_count))) return -1;
        const from: usize = @intCast(from_value);
        const to: usize = @intCast(to_value);
        adjacency[from] |= @as(u64, 1) << @intCast(to);
        transpose[to] |= @as(u64, 1) << @intCast(from);
    }
    var visited: [MAX_VERTEX_COUNT]bool = [_]bool{false} ** MAX_VERTEX_COUNT;
    var order: [MAX_VERTEX_COUNT]usize = undefined;
    var order_length: usize = 0;
    for (0..vertex_count) |vertex| {
        if (!visited[vertex]) fillOrder(&adjacency, &visited, &order, &order_length, vertex_count, vertex);
    }
    visited = [_]bool{false} ** MAX_VERTEX_COUNT;
    var component_id: [MAX_VERTEX_COUNT]i64 = [_]i64{-1} ** MAX_VERTEX_COUNT;
    var component_count: usize = 0;
    while (order_length > 0) {
        order_length -= 1;
        const vertex = order[order_length];
        if (!visited[vertex]) {
            collectComponent(&transpose, &visited, &component_id, vertex_count, vertex, @intCast(component_count));
            component_count += 1;
        }
    }
    return encodeComponents(&component_id, vertex_count, component_count, output, output_capacity);
}
