const MAX_N: usize = 128;
const MAX_Q: usize = 256;
const MAX_INPUT_VALUES: usize = 2 * MAX_N + 1 + 3 * MAX_Q;
const MAX_VALUE: i64 = 1_000_000;

fn fenwickAdd(tree: *[MAX_N + 1]i64, n: usize, position: usize, delta: i64) void {
    var index = position + 1;
    while (index <= n) {
        tree[index] += delta;
        index += index & (~index + 1);
    }
}

fn fenwickPrefix(tree: *const [MAX_N + 1]i64, count: usize) i64 {
    var total: i64 = 0;
    var index = count;
    while (index > 0) {
        total += tree[index];
        index -= index & (~index + 1);
    }
    return total;
}

fn storeI64Le(output: [*c]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(byte * 8));
}

export fn vertex_add_subtree_sum(input: [*c]const i64, length: usize,
    output: [*c]u8, capacity: usize) i64 {
    if (input == null or length < 2 or length > MAX_INPUT_VALUES) return -1;
    const packed = input[0..length];
    const n_value = packed[0];
    const q_value = packed[1];
    if (n_value < 1 or n_value > @as(i64, @intCast(MAX_N)) or
        q_value < 0 or q_value > @as(i64, @intCast(MAX_Q))) return -1;
    const n: usize = @intCast(n_value);
    const q: usize = @intCast(q_value);
    if (length != 2 * n + 1 + 3 * q) return -1;

    var values: [MAX_N]i64 = @splat(0);
    var first_child: [MAX_N]i64 = @splat(-1);
    var next_sibling: [MAX_N]i64 = @splat(-1);
    for (0..n) |vertex| {
        values[vertex] = packed[2 + vertex];
        if (values[vertex] < 0 or values[vertex] > MAX_VALUE) return -1;
    }
    const parent_start = 2 + n;
    for (1..n) |vertex| {
        const parent_value = packed[parent_start + vertex - 1];
        if (parent_value < 0 or @as(usize, @intCast(parent_value)) >= vertex) return -1;
        const parent: usize = @intCast(parent_value);
        next_sibling[vertex] = first_child[parent];
        first_child[parent] = @intCast(vertex);
    }

    var tin: [MAX_N]usize = @splat(0);
    var tout: [MAX_N]usize = @splat(0);
    var stack_node: [MAX_N]usize = @splat(0);
    var stack_next_child: [MAX_N]i64 = @splat(0);
    var timer: usize = 0;
    var top: usize = 1;
    stack_node[0] = 0;
    stack_next_child[0] = first_child[0];
    tin[0] = timer;
    timer += 1;
    while (top > 0) {
        const frame = top - 1;
        const child_value = stack_next_child[frame];
        if (child_value < 0) {
            tout[stack_node[frame]] = timer;
            top -= 1;
            continue;
        }
        const child: usize = @intCast(child_value);
        stack_next_child[frame] = next_sibling[child];
        tin[child] = timer;
        timer += 1;
        stack_node[top] = child;
        stack_next_child[top] = first_child[child];
        top += 1;
    }

    var fenwick: [MAX_N + 1]i64 = @splat(0);
    for (0..n) |vertex| fenwickAdd(&fenwick, n, tin[vertex], values[vertex]);
    var answers: [MAX_Q]i64 = @splat(0);
    var answer_count: usize = 0;
    const operation_start = parent_start + n - 1;
    for (0..q) |operation_index| {
        const offset = operation_start + 3 * operation_index;
        const kind = packed[offset];
        const vertex_value = packed[offset + 1];
        const operand = packed[offset + 2];
        if (kind == 0) {
            if (vertex_value < 0 or vertex_value >= n_value or operand < 0 or operand > MAX_VALUE) return -1;
            const vertex: usize = @intCast(vertex_value);
            values[vertex] += operand;
            fenwickAdd(&fenwick, n, tin[vertex], operand);
        } else if (kind == 1) {
            if (vertex_value < 0 or vertex_value >= n_value or operand != 0) return -1;
            const vertex: usize = @intCast(vertex_value);
            answers[answer_count] = fenwickPrefix(&fenwick, tout[vertex]) - fenwickPrefix(&fenwick, tin[vertex]);
            answer_count += 1;
        } else return -1;
    }

    const output_bytes = 8 * answer_count;
    if (output_bytes > 0 and (output == null or capacity < output_bytes)) return -2;
    for (0..answer_count) |index| storeI64Le(output, 8 * index, answers[index]);
    return @intCast(output_bytes);
}
