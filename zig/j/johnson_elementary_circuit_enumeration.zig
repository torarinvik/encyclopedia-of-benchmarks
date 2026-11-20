const MAX_VERTICES: usize = 8;
const MAX_EDGES: usize = 24;
const MAX_INPUT_LENGTH: usize = 51;
const COUNT_SCALE: i64 = 1_000_000_000_000;

const SccState = struct {
    graph: [MAX_VERTICES * MAX_VERTICES]bool,
    n: usize,
    lower_bound: usize,
    next_index: usize = 0,
    component_count: usize = 0,
    stack_length: usize = 0,
    index: [MAX_VERTICES]i32 = @splat(-1),
    low_link: [MAX_VERTICES]usize = @splat(0),
    component_id: [MAX_VERTICES]i32 = @splat(-1),
    on_stack: [MAX_VERTICES]bool = @splat(false),
    stack: [MAX_VERTICES]usize = @splat(0),
    component_size: [MAX_VERTICES]usize = @splat(0),
    component_minimum: [MAX_VERTICES]usize = @splat(MAX_VERTICES),
};

const Selection = struct {
    start: usize,
    component: i32,
    component_id: [MAX_VERTICES]i32,
};

const CircuitState = struct {
    graph: [MAX_VERTICES * MAX_VERTICES]bool,
    n: usize,
    start: usize,
    selected_component: i32,
    depth: usize = 0,
    component_id: [MAX_VERTICES]i32,
    blocked: [MAX_VERTICES]bool = @splat(false),
    dependencies: [MAX_VERTICES * MAX_VERTICES]bool = @splat(false),
    path: [MAX_VERTICES]usize = @splat(0),
    count: i64 = 0,
    code_sum: i64 = 0,
};

fn strongConnect(vertex: usize, state: *SccState) void {
    state.index[vertex] = @intCast(state.next_index);
    state.low_link[vertex] = state.next_index;
    state.next_index += 1;
    state.stack[state.stack_length] = vertex;
    state.stack_length += 1;
    state.on_stack[vertex] = true;

    for (state.lower_bound..state.n) |neighbor| {
        if (!state.graph[vertex * MAX_VERTICES + neighbor]) continue;
        if (state.index[neighbor] < 0) {
            strongConnect(neighbor, state);
            state.low_link[vertex] = @min(state.low_link[vertex], state.low_link[neighbor]);
        } else if (state.on_stack[neighbor]) {
            state.low_link[vertex] = @min(state.low_link[vertex], @as(usize, @intCast(state.index[neighbor])));
        }
    }

    if (state.low_link[vertex] == @as(usize, @intCast(state.index[vertex]))) {
        const component = state.component_count;
        var size: usize = 0;
        var minimum: usize = state.n;
        while (true) {
            state.stack_length -= 1;
            const member = state.stack[state.stack_length];
            state.on_stack[member] = false;
            state.component_id[member] = @intCast(component);
            size += 1;
            minimum = @min(minimum, member);
            if (member == vertex) break;
        }
        state.component_size[component] = size;
        state.component_minimum[component] = minimum;
        state.component_count += 1;
    }
}

fn findSelectedComponent(n: usize, lower_bound: usize, graph: [MAX_VERTICES * MAX_VERTICES]bool) Selection {
    var state = SccState{ .graph = graph, .n = n, .lower_bound = lower_bound };
    for (lower_bound..n) |vertex| {
        if (state.index[vertex] < 0) strongConnect(vertex, &state);
    }
    var selection = Selection{
        .start = n,
        .component = -1,
        .component_id = state.component_id,
    };
    for (0..state.component_count) |component| {
        if (state.component_size[component] > 1 and state.component_minimum[component] < selection.start) {
            selection.start = state.component_minimum[component];
            selection.component = @intCast(component);
        }
    }
    return selection;
}

fn unblock(vertex: usize, state: *CircuitState) void {
    if (!state.blocked[vertex]) return;
    state.blocked[vertex] = false;
    for (0..state.n) |dependent| {
        const slot = vertex * MAX_VERTICES + dependent;
        if (state.dependencies[slot]) {
            state.dependencies[slot] = false;
            if (state.blocked[dependent]) unblock(dependent, state);
        }
    }
}

fn recordCycle(state: *CircuitState) void {
    var code: i64 = 0;
    var place: i64 = 1;
    for (0..state.depth) |index| {
        code += (@as(i64, @intCast(state.path[index])) + 1) * place;
        place *= 9;
    }
    state.count += 1;
    state.code_sum += code;
}

fn circuit(vertex: usize, state: *CircuitState) bool {
    state.path[state.depth] = vertex;
    state.depth += 1;
    state.blocked[vertex] = true;
    var found = false;
    for (0..state.n) |neighbor| {
        if (!state.graph[vertex * MAX_VERTICES + neighbor]
            or state.component_id[neighbor] != state.selected_component) continue;
        if (neighbor == state.start) {
            recordCycle(state);
            found = true;
        } else if (!state.blocked[neighbor] and circuit(neighbor, state)) {
            found = true;
        }
    }
    if (found) {
        unblock(vertex, state);
    } else {
        for (0..state.n) |neighbor| {
            if (state.graph[vertex * MAX_VERTICES + neighbor]
                and state.component_id[neighbor] == state.selected_component) {
                state.dependencies[neighbor * MAX_VERTICES + vertex] = true;
            }
        }
    }
    state.depth -= 1;
    return found;
}

export fn johnson_elementary_circuit_enumeration(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length < 2 or length > MAX_INPUT_LENGTH) return -1;
    const input = input_opt.?[0..length];
    const n_value = input[0];
    const m_value = input[1];
    if (n_value < 1 or n_value > 8 or m_value < 0 or m_value > 24) return -1;
    const n: usize = @intCast(n_value);
    const m: usize = @intCast(m_value);
    if (length != 2 + 2 * m) return -1;

    var graph: [MAX_VERTICES * MAX_VERTICES]bool = @splat(false);
    for (0..m) |edge_index| {
        const from_value = input[2 + 2 * edge_index];
        const to_value = input[3 + 2 * edge_index];
        if (from_value < 0 or from_value >= @as(i64, @intCast(n))
            or to_value < 0 or to_value >= @as(i64, @intCast(n)) or from_value == to_value) return -1;
        const from: usize = @intCast(from_value);
        const to: usize = @intCast(to_value);
        const slot = from * MAX_VERTICES + to;
        if (graph[slot]) return -1;
        graph[slot] = true;
    }

    var lower_bound: usize = 0;
    var total_count: i64 = 0;
    var total_code_sum: i64 = 0;
    while (lower_bound < n) {
        const selection = findSelectedComponent(n, lower_bound, graph);
        if (selection.component < 0) break;
        var state = CircuitState{
            .graph = graph,
            .n = n,
            .start = selection.start,
            .selected_component = selection.component,
            .component_id = selection.component_id,
        };
        _ = circuit(selection.start, &state);
        total_count += state.count;
        total_code_sum += state.code_sum;
        lower_bound = selection.start + 1;
    }
    return total_count * COUNT_SCALE + total_code_sum;
}
