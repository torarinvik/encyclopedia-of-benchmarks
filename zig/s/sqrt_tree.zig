// Adapted from cp-algorithms Sqrt Tree; CC BY-SA 4.0, see package LICENSE.txt.
const MAX_ITEMS: usize = 256;
const MAX_QUERIES: usize = 256;
const MAX_LEVELS: usize = 16;
const MAX_NODES: usize = 512;
const MAX_BETWEEN: usize = 512;
const MAX_INPUT_VALUES: usize = 770;
const VALUE_LIMIT: i64 = 1_000_000_000;

const State = struct {
    values: [MAX_ITEMS]i64 = @splat(0),
    prefix: [MAX_LEVELS * MAX_ITEMS]i64 = @splat(0),
    suffix: [MAX_LEVELS * MAX_ITEMS]i64 = @splat(0),
    between: [MAX_LEVELS * MAX_BETWEEN]i64 = @splat(0),
    used_values: [MAX_LEVELS]usize = @splat(0),
    used_between: [MAX_LEVELS]usize = @splat(0),
    left: [MAX_NODES]usize = @splat(0),
    right: [MAX_NODES]usize = @splat(0),
    depth: [MAX_NODES]usize = @splat(0),
    value_offset: [MAX_NODES]usize = @splat(0),
    between_offset: [MAX_NODES]usize = @splat(0),
    block_size: [MAX_NODES]usize = @splat(0),
    block_count: [MAX_NODES]usize = @splat(0),
    child_start: [MAX_NODES]usize = @splat(0),
    children: [MAX_NODES]usize = @splat(0),
    node_count: usize = 0,
    child_count: usize = 0,
};

fn createNode(state: *State, left: usize, right: usize, depth: usize) usize {
    const node = state.node_count;
    state.node_count += 1;
    state.left[node] = left;
    state.right[node] = right;
    state.depth[node] = depth;
    return node;
}

fn buildNode(state: *State, node: usize) void {
    const left = state.left[node];
    const right = state.right[node];
    const node_length = right - left;
    const depth = state.depth[node];
    if (node_length <= 2) return;
    var block_size: usize = 1;
    while (block_size * block_size < node_length) : (block_size += 1) {}
    const block_count = (node_length + block_size - 1) / block_size;
    const value_offset = state.used_values[depth];
    const between_offset = state.used_between[depth];
    state.value_offset[node] = value_offset;
    state.between_offset[node] = between_offset;
    state.block_size[node] = block_size;
    state.block_count[node] = block_count;
    state.used_values[depth] += node_length;
    state.used_between[depth] += block_count * block_count;

    var block_min: [MAX_ITEMS]i64 = @splat(0);
    for (0..block_count) |block| {
        const start = left + block * block_size;
        const end = @min(start + block_size, right);
        const first = value_offset + start - left;
        state.prefix[depth * MAX_ITEMS + first] = state.values[start];
        for (start + 1..end) |index| {
            const slot = value_offset + index - left;
            state.prefix[depth * MAX_ITEMS + slot] = @min(state.prefix[depth * MAX_ITEMS + slot - 1], state.values[index]);
        }
        const last = value_offset + end - 1 - left;
        state.suffix[depth * MAX_ITEMS + last] = state.values[end - 1];
        var index = end - 1;
        while (index > start) {
            index -= 1;
            const slot = value_offset + index - left;
            state.suffix[depth * MAX_ITEMS + slot] = @min(state.values[index], state.suffix[depth * MAX_ITEMS + slot + 1]);
        }
        block_min[block] = state.prefix[depth * MAX_ITEMS + last];
    }
    for (0..block_count) |first| {
        var aggregate = block_min[first];
        var last = first;
        while (last < block_count) : (last += 1) {
            if (last != first) aggregate = @min(aggregate, block_min[last]);
            state.between[depth * MAX_BETWEEN + between_offset + first * block_count + last] = aggregate;
        }
    }

    const child_start = state.child_count;
    state.child_start[node] = child_start;
    for (0..block_count) |block| {
        const start = left + block * block_size;
        const end = @min(start + block_size, right);
        const child = createNode(state, start, end, depth + 1);
        state.children[state.child_count] = child;
        state.child_count += 1;
    }
    for (0..block_count) |block| buildNode(state, state.children[child_start + block]);
}

fn queryNode(state: *const State, node: usize, left: usize, right: usize) i64 {
    const node_left = state.left[node];
    const node_right = state.right[node];
    if (node_right - node_left <= 2) {
        var answer = state.values[left];
        var index = left + 1;
        while (index <= right) : (index += 1) answer = @min(answer, state.values[index]);
        return answer;
    }
    const block_size = state.block_size[node];
    const left_block = (left - node_left) / block_size;
    const right_block = (right - node_left) / block_size;
    if (left_block == right_block) return queryNode(state, state.children[state.child_start[node] + left_block], left, right);
    const depth = state.depth[node];
    const offset = state.value_offset[node];
    var answer = state.suffix[depth * MAX_ITEMS + offset + left - node_left];
    if (left_block + 1 < right_block) {
        const count = state.block_count[node];
        const middle = state.between_offset[node] + (left_block + 1) * count + right_block - 1;
        answer = @min(answer, state.between[depth * MAX_BETWEEN + middle]);
    }
    return @min(answer, state.prefix[depth * MAX_ITEMS + offset + right - node_left]);
}

fn storeI64Le(output: [*c]u8, offset: usize, value: i64) void {
    var bits: u64 = @bitCast(value);
    for (0..8) |byte| {
        output[offset + byte] = @truncate(bits & 255);
        bits >>= 8;
    }
}

export fn sqrt_tree(input: [*c]const i64, length: usize, output: [*c]u8, output_capacity: usize) i64 {
    if (input == null or length < 2 or length > MAX_INPUT_VALUES) return -1;
    const item_count_value = input[0];
    const query_count_value = input[1];
    if (item_count_value < 1 or item_count_value > MAX_ITEMS or query_count_value < 0 or query_count_value > MAX_QUERIES) return -1;
    const item_count: usize = @intCast(item_count_value);
    const query_count: usize = @intCast(query_count_value);
    if (length != 2 + item_count + 2 * query_count) return -1;
    for (0..item_count) |index| {
        if (input[2 + index] < -VALUE_LIMIT or input[2 + index] > VALUE_LIMIT) return -1;
    }
    const query_offset = 2 + item_count;
    for (0..query_count) |query| {
        const left = input[query_offset + 2 * query];
        const right = input[query_offset + 2 * query + 1];
        if (left < 0 or right < left or right >= item_count_value) return -1;
    }
    const required = 8 * query_count;
    if (output_capacity < required or (required != 0 and output == null)) return -2;

    var state: State = .{};
    for (0..item_count) |index| state.values[index] = input[index + 2];
    const root = createNode(&state, 0, item_count, 0);
    buildNode(&state, root);
    for (0..query_count) |query| {
        const left: usize = @intCast(input[query_offset + 2 * query]);
        const right: usize = @intCast(input[query_offset + 2 * query + 1]);
        storeI64Le(output, 8 * query, queryNode(&state, root, left, right));
    }
    return @intCast(required);
}
