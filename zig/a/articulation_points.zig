const MAX_VERTEX_COUNT: usize = 64;
const MAX_EDGE_COUNT: i64 = 2047;
const MAX_INPUT_LENGTH: usize = 2 + 2 * @as(usize, @intCast(MAX_EDGE_COUNT));

const GraphState = struct {
    adjacency: [MAX_VERTEX_COUNT]u64,
    discovery: [MAX_VERTEX_COUNT]i64,
    low: [MAX_VERTEX_COUNT]i64,
    parent: [MAX_VERTEX_COUNT]i64,
    is_articulation: [MAX_VERTEX_COUNT]bool,
};

fn visitVertex(state: *GraphState, vertex_count: usize, vertex: usize, time: *usize) void {
    state.discovery[vertex] = @intCast(time.*);
    state.low[vertex] = @intCast(time.*);
    time.* += 1;
    var child_count: usize = 0;
    for (0..vertex_count) |neighbor| {
        if (state.adjacency[vertex] & (@as(u64, 1) << @intCast(neighbor))) == 0) continue;
        if (state.discovery[neighbor] == -1) {
            state.parent[neighbor] = @intCast(vertex);
            child_count += 1;
            visitVertex(state, vertex_count, neighbor, time);
            if (state.low[neighbor] < state.low[vertex]) state.low[vertex] = state.low[neighbor];
            if (state.parent[vertex] == -1 and child_count > 1) state.is_articulation[vertex] = true;
            if (state.parent[vertex] != -1 and state.low[neighbor] >= state.discovery[vertex])
                state.is_articulation[vertex] = true;
        } else if (@as(i64, @intCast(neighbor)) != state.parent[vertex] and
                   state.discovery[neighbor] < state.low[vertex]) {
            state.low[vertex] = state.discovery[neighbor];
        }
    }
}

export fn articulation_points(input: [*]const i64, length: usize,
    output: [*]u8, output_capacity: usize) i64 {
    if (length < 2 or length > MAX_INPUT_LENGTH or input[0] < 0 or
        input[0] > @as(i64, @intCast(MAX_VERTEX_COUNT)) or input[1] < 0 or input[1] > MAX_EDGE_COUNT) return -1;
    const vertex_count: usize = @intCast(input[0]);
    const edge_count: usize = @intCast(input[1]);
    if (length != 2 + 2 * edge_count) return -1;
    var state: GraphState = undefined;
    for (0..MAX_VERTEX_COUNT) |vertex| {
        state.adjacency[vertex] = 0;
        state.discovery[vertex] = -1;
        state.low[vertex] = 0;
        state.parent[vertex] = -1;
        state.is_articulation[vertex] = false;
    }
    for (0..edge_count) |edge| {
        const left_value = input[2 + 2 * edge];
        const right_value = input[3 + 2 * edge];
        if (left_value < 0 or right_value < 0 or left_value >= @as(i64, @intCast(vertex_count)) or
            right_value >= @as(i64, @intCast(vertex_count))) return -1;
        const left: usize = @intCast(left_value);
        const right: usize = @intCast(right_value);
        state.adjacency[left] |= @as(u64, 1) << @intCast(right);
        state.adjacency[right] |= @as(u64, 1) << @intCast(left);
    }
    var time: usize = 0;
    for (0..vertex_count) |vertex| {
        if (state.discovery[vertex] == -1) visitVertex(&state, vertex_count, vertex, &time);
    }
    var point_count: usize = 0;
    for (0..vertex_count) |vertex| {
        if (state.is_articulation[vertex]) point_count += 1;
    }
    if (output_capacity < point_count) return -2;
    var position: usize = 0;
    for (0..vertex_count) |vertex| {
        if (state.is_articulation[vertex]) {
            output[position] = @intCast(vertex);
            position += 1;
        }
    }
    return @intCast(point_count);
}
