const MAX_VERTICES: usize = 7;
const MAX_STATES: usize = 4096;

const SearchState = struct {
    distance: i32,
    heuristic: i32,
    path_length: usize,
    path: [MAX_VERTICES]i32,
};

fn writeI64(output: [*c]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |i| output[offset + i] = @truncate(bits >> @intCast(i * 8));
}

pub export fn astar_java_weighted_graph(input: [*c]const i64, length: usize,
    output: [*c]u8, capacity: usize) i64 {
    if (input == null or length < 5) return -1;
    const n64 = input[0];
    const m64 = input[1];
    const start64 = input[2];
    const target64 = input[3];
    if (n64 < 1 or n64 > MAX_VERTICES or m64 < 0 or m64 > 16 or
        start64 < 0 or start64 >= n64 or target64 < 0 or target64 >= n64 or
        length != @as(usize, @intCast(4 + n64 + 3 * m64))) return -1;
    const n: usize = @intCast(n64);
    const m: usize = @intCast(m64);
    const start: usize = @intCast(start64);
    const target: usize = @intCast(target64);
    var heuristic: [MAX_VERTICES]i32 = [_]i32{0} ** MAX_VERTICES;
    var adjacent: [MAX_VERTICES][MAX_VERTICES]i32 = undefined;
    var weights: [MAX_VERTICES][MAX_VERTICES]i32 = undefined;
    var degree: [MAX_VERTICES]usize = [_]usize{0} ** MAX_VERTICES;
    for (0..MAX_VERTICES) |u| {
        for (0..MAX_VERTICES) |v| {
            adjacent[u][v] = 0;
            weights[u][v] = 0;
        }
    }
    for (0..n) |i| {
        if (input[4 + i] < -1000 or input[4 + i] > 1000) return -1;
        heuristic[i] = @intCast(input[4 + i]);
    }
    var position: usize = 4 + n;
    for (0..m) |_| {
        const u64 = input[position];
        const v64 = input[position + 1];
        const weight64 = input[position + 2];
        position += 3;
        if (u64 < 0 or u64 >= n64 or v64 < 0 or v64 >= n64 or u64 == v64 or weight64 < 0 or weight64 > 1000) return -1;
        const u: usize = @intCast(u64);
        const v: usize = @intCast(v64);
        for (0..degree[u]) |i| {
            if (adjacent[u][i] == @as(i32, @intCast(v))) return -1;
        }
        adjacent[u][degree[u]] = @intCast(v);
        weights[u][degree[u]] = @intCast(weight64);
        degree[u] += 1;
        adjacent[v][degree[v]] = @intCast(u);
        weights[v][degree[v]] = @intCast(weight64);
        degree[v] += 1;
    }
    const empty = SearchState{ .distance = 0, .heuristic = 0, .path_length = 0, .path = [_]i32{0} ** MAX_VERTICES };
    var states: [MAX_STATES]SearchState = [_]SearchState{empty} ** MAX_STATES;
    var heap: [MAX_STATES]usize = [_]usize{0} ** MAX_STATES;
    var state_count: usize = 1;
    var heap_size: usize = 1;
    states[0].heuristic = heuristic[start];
    states[0].path_length = 1;
    states[0].path[0] = @intCast(start);
    heap[0] = 0;
    var found = false;
    var solution: usize = 0;
    while (heap_size > 0) {
        const current_index = heap[0];
        const last = heap[heap_size - 1];
        heap_size -= 1;
        if (heap_size > 0) {
            var i: usize = 0;
            const half = heap_size / 2;
            while (i < half) {
                var child = 2 * i + 1;
                var child_index = heap[child];
                const right = child + 1;
                if (right < heap_size and states[heap[right]].distance + states[heap[right]].heuristic <
                    states[child_index].distance + states[child_index].heuristic) {
                    child = right;
                    child_index = heap[right];
                }
                if (states[last].distance + states[last].heuristic <=
                    states[child_index].distance + states[child_index].heuristic) break;
                heap[i] = child_index;
                i = child;
            }
            heap[i] = last;
        }
        const current = states[current_index];
        const current_vertex: usize = @intCast(current.path[current.path_length - 1]);
        if (current_vertex == target) { found = true; solution = current_index; break; }
        for (0..degree[current_vertex]) |edge| {
            const next = adjacent[current_vertex][edge];
            var in_path = false;
            for (0..current.path_length) |i| {
                if (current.path[i] == next) { in_path = true; break; }
            }
            if (in_path) continue;
            if (state_count >= MAX_STATES or heap_size >= MAX_STATES) return -1;
            var child_state = empty;
            child_state.distance = current.distance + weights[current_vertex][edge];
            child_state.heuristic = heuristic[@intCast(next)];
            child_state.path_length = current.path_length + 1;
            for (0..current.path_length) |i| child_state.path[i] = current.path[i];
            child_state.path[current.path_length] = next;
            states[state_count] = child_state;
            const next_state = state_count;
            state_count += 1;
            var i = heap_size;
            heap_size += 1;
            while (i > 0) {
                const parent = (i - 1) / 2;
                const parent_index = heap[parent];
                if (states[parent_index].distance + states[parent_index].heuristic <=
                    child_state.distance + child_state.heuristic) break;
                heap[i] = parent_index;
                i = parent;
            }
            heap[i] = next_state;
        }
    }
    var result: [3 + MAX_VERTICES]i64 = [_]i64{0} ** (3 + MAX_VERTICES);
    var result_words: usize = 3;
    if (!found) {
        result[0] = -1;
        result[1] = -1;
        result[2] = 0;
    } else {
        const state = states[solution];
        result[0] = state.distance;
        result[1] = state.heuristic;
        result[2] = @intCast(state.path_length);
        result_words += state.path_length;
        for (0..state.path_length) |i| result[3 + i] = state.path[i];
    }
    const output_bytes = result_words * 8;
    if (output == null or capacity < output_bytes) return -2;
    for (0..result_words) |i| writeI64(output, i * 8, result[i]);
    return @intCast(output_bytes);
}
