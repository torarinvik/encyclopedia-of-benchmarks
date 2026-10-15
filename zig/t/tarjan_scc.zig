const MAX_VERTEX_COUNT: usize = 40;
const MAX_EDGE_COUNT: i64 = 2047;
const MAX_INPUT_LENGTH: usize = 2 + 2 * @as(usize, @intCast(MAX_EDGE_COUNT));

const GraphState = struct {
    adjacency: [MAX_VERTEX_COUNT]u64,
    on_stack: [MAX_VERTEX_COUNT]bool,
    stack: [MAX_VERTEX_COUNT]usize,
    stack_length: usize,
    discovery: [MAX_VERTEX_COUNT]i64,
    low: [MAX_VERTEX_COUNT]i64,
    component_id: [MAX_VERTEX_COUNT]i64,
    time: usize,
    component_count: usize,
};

fn visitVertex(state: *GraphState, vertex_count: usize, vertex: usize) void {
    state.discovery[vertex] = @intCast(state.time);
    state.low[vertex] = @intCast(state.time);
    state.time += 1;
    state.on_stack[vertex] = true;
    state.stack[state.stack_length] = vertex;
    state.stack_length += 1;
    for (0..vertex_count) |neighbor| {
        if (state.adjacency[vertex] & (@as(u64, 1) << @intCast(neighbor)) == 0) continue;
        if (state.discovery[neighbor] == -1) {
            visitVertex(state, vertex_count, neighbor);
            if (state.low[neighbor] < state.low[vertex]) state.low[vertex] = state.low[neighbor];
        } else if (state.on_stack[neighbor] and state.discovery[neighbor] < state.low[vertex]) {
            state.low[vertex] = state.discovery[neighbor];
        }
    }
    if (state.low[vertex] == state.discovery[vertex]) {
        while (true) {
            state.stack_length -= 1;
            const member = state.stack[state.stack_length];
            state.on_stack[member] = false;
            state.component_id[member] = @intCast(state.component_count);
            if (member == vertex) break;
        }
        state.component_count += 1;
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

export fn tarjan_scc(input: [*]const i64, length: usize,
    output: [*]u8, output_capacity: usize) i64 {
    if (length < 2 or length > MAX_INPUT_LENGTH or input[0] < 0 or
        input[0] > @as(i64, @intCast(MAX_VERTEX_COUNT)) or input[1] < 0 or input[1] > MAX_EDGE_COUNT) return -1;
    const vertex_count: usize = @intCast(input[0]);
    const edge_count: usize = @intCast(input[1]);
    if (length != 2 + 2 * edge_count) return -1;
    var state: GraphState = undefined;
    state.adjacency = [_]u64{0} ** MAX_VERTEX_COUNT;
    state.on_stack = [_]bool{false} ** MAX_VERTEX_COUNT;
    state.stack = undefined;
    state.stack_length = 0;
    state.discovery = [_]i64{-1} ** MAX_VERTEX_COUNT;
    state.low = [_]i64{0} ** MAX_VERTEX_COUNT;
    state.component_id = [_]i64{-1} ** MAX_VERTEX_COUNT;
    state.time = 0;
    state.component_count = 0;
    for (0..edge_count) |edge| {
        const from_value = input[2 + 2 * edge];
        const to_value = input[3 + 2 * edge];
        if (from_value < 0 or to_value < 0 or from_value >= @as(i64, @intCast(vertex_count)) or
            to_value >= @as(i64, @intCast(vertex_count))) return -1;
        const from: usize = @intCast(from_value);
        const to: usize = @intCast(to_value);
        state.adjacency[from] |= @as(u64, 1) << @intCast(to);
    }
    for (0..vertex_count) |vertex| {
        if (state.discovery[vertex] == -1) visitVertex(&state, vertex_count, vertex);
    }
    return encodeComponents(&state.component_id, vertex_count, state.component_count, output, output_capacity);
}
