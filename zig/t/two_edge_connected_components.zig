/// Tarjan low-link bridge detection followed by flooding across non-bridges.
const MAX_N: usize = 6;
const MAX_M: usize = 10;
const MAX_ADJ: usize = 20;
const MAX_OUTPUT_VALUES: usize = 13;
const MAX_OUTPUT_BYTES: usize = 104;
const MAX_INPUT_LENGTH: usize = 22;

const Context = struct {
    n: usize = 0,
    m: usize = 0,
    degree: [MAX_N]usize = [_]usize{0} ** MAX_N,
    adjacent_vertex: [MAX_N * MAX_ADJ]usize = [_]usize{0} ** (MAX_N * MAX_ADJ),
    adjacent_edge: [MAX_N * MAX_ADJ]usize = [_]usize{0} ** (MAX_N * MAX_ADJ),
    discovery: [MAX_N]i32 = [_]i32{-1} ** MAX_N,
    low: [MAX_N]i32 = [_]i32{0} ** MAX_N,
    is_bridge: [MAX_M]bool = [_]bool{false} ** MAX_M,
    clock: usize = 0,
    component: [MAX_N]i32 = [_]i32{-1} ** MAX_N,
    block_vertices: [MAX_N * MAX_N]usize = [_]usize{0} ** (MAX_N * MAX_N),
    block_size: [MAX_N]usize = [_]usize{0} ** MAX_N,
    block_count: usize = 0,
};

fn findBridges(context: *Context, vertex: usize, parent_edge: usize) void {
    context.discovery[vertex] = @intCast(context.clock);
    context.low[vertex] = @intCast(context.clock);
    context.clock += 1;
    for (0..context.degree[vertex]) |slot| {
        const index = vertex * MAX_ADJ + slot;
        const neighbor = context.adjacent_vertex[index];
        const edge = context.adjacent_edge[index];
        if (edge == parent_edge) continue;
        if (context.discovery[neighbor] < 0) {
            findBridges(context, neighbor, edge);
            context.low[vertex] = @min(context.low[vertex], context.low[neighbor]);
            if (context.low[neighbor] > context.discovery[vertex]) context.is_bridge[edge] = true;
        } else if (context.discovery[neighbor] < context.low[vertex]) {
            context.low[vertex] = context.discovery[neighbor];
        }
    }
}

fn assignComponents(context: *Context) void {
    var queue = [_]usize{0} ** MAX_N;
    for (0..context.n) |root| {
        if (context.component[root] >= 0) continue;
        const block = context.block_count;
        const block_label: i32 = @intCast(block);
        context.block_count += 1;
        var head: usize = 0;
        var tail: usize = 0;
        context.component[root] = block_label;
        queue[tail] = root;
        tail += 1;
        while (head < tail) {
            const vertex = queue[head];
            head += 1;
            for (0..context.degree[vertex]) |slot| {
                const index = vertex * MAX_ADJ + slot;
                const neighbor = context.adjacent_vertex[index];
                const edge = context.adjacent_edge[index];
                if (context.is_bridge[edge] or context.component[neighbor] >= 0) continue;
                context.component[neighbor] = block_label;
                queue[tail] = neighbor;
                tail += 1;
            }
        }
        for (0..context.n) |vertex| {
            if (context.component[vertex] == block_label) {
                context.block_vertices[block * MAX_N + context.block_size[block]] = vertex;
                context.block_size[block] += 1;
            }
        }
    }
}

fn blockLess(context: *const Context, left: usize, right: usize) bool {
    const common = @min(context.block_size[left], context.block_size[right]);
    for (0..common) |i| {
        const a = context.block_vertices[left * MAX_N + i];
        const b = context.block_vertices[right * MAX_N + i];
        if (a != b) return a < b;
    }
    return context.block_size[left] < context.block_size[right];
}

fn storeU64Le(output: *[MAX_OUTPUT_BYTES]u8, offset: usize, value: u64) void {
    for (0..8) |byte| output.*[offset + byte] = @intCast((value >> @intCast(byte * 8)) & 0xff);
}

/// Packed input `[N, M, (u, v)*M]`; writes canonical sorted component vertex sets.
export fn two_edge_connected_components(input: [*c]const i64, length: usize,
    output: [*c]u8, capacity: usize) i64 {
    if (input == null or length < 2 or length > MAX_INPUT_LENGTH) return -1;
    const n_value = input[0];
    const m_value = input[1];
    if (n_value < 1 or n_value > MAX_N or m_value < 0 or m_value > MAX_M) return -1;
    const n: usize = @intCast(n_value);
    const m: usize = @intCast(m_value);
    if (length != 2 + 2 * m) return -1;

    var context = Context{ .n = n, .m = m };
    for (0..m) |edge| {
        const left = input[2 + 2 * edge];
        const right = input[3 + 2 * edge];
        if (left < 0 or left >= n_value or right < 0 or right >= n_value) return -1;
        const u: usize = @intCast(left);
        const v: usize = @intCast(right);
        const u_slot = context.degree[u];
        context.degree[u] += 1;
        const v_slot = context.degree[v];
        context.degree[v] += 1;
        context.adjacent_vertex[u * MAX_ADJ + u_slot] = v;
        context.adjacent_edge[u * MAX_ADJ + u_slot] = edge;
        context.adjacent_vertex[v * MAX_ADJ + v_slot] = u;
        context.adjacent_edge[v * MAX_ADJ + v_slot] = edge;
    }
    for (0..n) |root| {
        if (context.discovery[root] < 0) findBridges(&context, root, MAX_M);
    }
    assignComponents(&context);

    var order = [_]usize{0} ** MAX_N;
    for (0..context.block_count) |i| {
        var position = i;
        order[i] = i;
        while (position > 0 and blockLess(&context, order[position], order[position - 1])) {
            const temporary = order[position];
            order[position] = order[position - 1];
            order[position - 1] = temporary;
            position -= 1;
        }
    }
    var staged = [_]u8{0} ** MAX_OUTPUT_BYTES;
    var packed_count: usize = 0;
    storeU64Le(&staged, packed_count * 8, context.block_count);
    packed_count += 1;
    for (0..context.block_count) |i| {
        const block = order[i];
        storeU64Le(&staged, packed_count * 8, context.block_size[block]);
        packed_count += 1;
        for (0..context.block_size[block]) |j| {
            storeU64Le(&staged, packed_count * 8, context.block_vertices[block * MAX_N + j]);
            packed_count += 1;
        }
    }
    const bytes = 8 * packed_count;
    if (output == null or capacity < bytes) return -2;
    for (0..bytes) |byte| output[byte] = staged[byte];
    return @intCast(bytes);
}
