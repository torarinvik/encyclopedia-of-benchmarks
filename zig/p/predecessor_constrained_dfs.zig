const MAX_NODES: usize = 16;
const MAX_INPUT_VALUES: usize = 2 + MAX_NODES * MAX_NODES;
const MAX_EVENTS: usize = MAX_NODES + MAX_NODES * (MAX_NODES - 1) / 2;

fn visitNode(node: usize, count: usize, adjacent: *const [MAX_NODES * MAX_NODES]bool,
    predecessors: *const [MAX_NODES * MAX_NODES]bool, visited: *[MAX_NODES]bool,
    events: *[MAX_EVENTS * 3]i32, event_count: *usize, next_order: *i32) bool {
    if (event_count.* >= MAX_EVENTS) return false;
    visited[node] = true;
    const index = 3 * event_count.*;
    events[index] = 1; events[index + 1] = @intCast(node); events[index + 2] = next_order.*;
    event_count.* += 1; next_order.* += 1;
    for (0..count) |child| {
        if (!adjacent[node * MAX_NODES + child] or visited[child]) continue;
        var all_visited = true;
        for (0..count) |parent| {
            if (predecessors[child * MAX_NODES + parent] and !visited[parent]) { all_visited = false; break; }
        }
        if (all_visited) {
            if (!visitNode(child, count, adjacent, predecessors, visited, events, event_count, next_order)) return false;
        } else {
            if (event_count.* >= MAX_EVENTS) return false;
            const event_index = 3 * event_count.*;
            events[event_index] = 0; events[event_index + 1] = @intCast(child); events[event_index + 2] = -1;
            event_count.* += 1;
        }
    }
    return true;
}

fn writeI32Le(output: [*]u8, offset: usize, value: i32) void {
    const bits: u32 = @bitCast(value);
    for (0..4) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn predecessor_constrained_dfs(input: ?[*]const i64, length: usize,
    output: ?[*]u8, output_capacity: usize) i64 {
    if (input == null or length < 2 or length > MAX_INPUT_VALUES) return -1;
    const values = input.?;
    const raw_count = values[0]; const raw_start = values[1];
    if (raw_count < 1 or raw_count > @as(i64, @intCast(MAX_NODES)) or raw_start < 0 or raw_start >= raw_count) return -1;
    const count: usize = @intCast(raw_count);
    if (length != 2 + count * count) return -1;
    var adjacent = [_]bool{false} ** (MAX_NODES * MAX_NODES);
    var predecessors = [_]bool{false} ** (MAX_NODES * MAX_NODES);
    var indegree = [_]usize{0} ** MAX_NODES;
    for (0..count) |from| {
        for (0..count) |to| {
            const bit = values[2 + from * count + to];
            if ((bit != 0 and bit != 1) or (from == to and bit != 0)) return -1;
            if (bit == 1) {
                adjacent[from * MAX_NODES + to] = true;
                predecessors[to * MAX_NODES + from] = true;
                indegree[to] += 1;
            }
        }
    }
    var queue = [_]usize{0} ** MAX_NODES;
    var head: usize = 0; var tail: usize = 0;
    for (0..count) |node| { if (indegree[node] == 0) { queue[tail] = node; tail += 1; } }
    while (head < tail) {
        const node = queue[head]; head += 1;
        for (0..count) |child| {
            if (adjacent[node * MAX_NODES + child]) {
                indegree[child] -= 1;
                if (indegree[child] == 0) { queue[tail] = child; tail += 1; }
            }
        }
    }
    if (tail != count) return -1;
    var visited = [_]bool{false} ** MAX_NODES;
    var events = [_]i32{0} ** (MAX_EVENTS * 3);
    var event_count: usize = 0; var next_order: i32 = 0;
    if (!visitNode(@intCast(raw_start), count, &adjacent, &predecessors, &visited, &events, &event_count, &next_order)) return -1;
    const byte_count = 12 * event_count;
    if (output == null or output_capacity < byte_count) return -2;
    const output_ptr = output.?;
    for (0..event_count) |event| {
        const index = 3 * event;
        writeI32Le(output_ptr, 12 * event, events[index]);
        writeI32Le(output_ptr, 12 * event + 4, events[index + 1]);
        writeI32Le(output_ptr, 12 * event + 8, events[index + 2]);
    }
    return @intCast(byte_count);
}
