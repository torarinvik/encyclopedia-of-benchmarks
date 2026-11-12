/// Historical maximum segment tree with ordered lazy add/assign summaries.
const MAX_N: usize = 32;
const MAX_Q: usize = 32;
const TREE_SIZE: usize = 4 * MAX_N;
const MAX_INPUT: usize = 2 + MAX_N + 4 * MAX_Q;
const VALUE_LIMIT: i64 = 1000;

const Node = struct {
    maximum: i64 = 0,
    history_maximum: i64 = 0,
    add: i64 = 0,
    add_peak: i64 = 0,
    set_value: i64 = 0,
    set_peak: i64 = 0,
    has_set: bool = false,
};

fn applyAddSummary(node: *Node, net: i64, peak: i64) void {
    node.history_maximum = @max(node.history_maximum, node.maximum + peak);
    node.maximum += net;
    if (node.has_set) {
        node.set_peak = @max(node.set_peak, node.set_value + peak);
        node.set_value += net;
    } else {
        node.add_peak = @max(node.add_peak, node.add + peak);
        node.add += net;
    }
}

fn applyAdd(node: *Node, delta: i64) void {
    if (node.has_set) {
        node.set_peak = @max(node.set_peak, node.set_value + delta);
        node.set_value += delta;
    } else {
        node.add_peak = @max(node.add_peak, node.add + delta);
        node.add += delta;
    }
    node.history_maximum = @max(node.history_maximum, node.maximum + delta);
    node.maximum += delta;
}

fn applySetSummary(node: *Node, value: i64, peak: i64) void {
    node.history_maximum = @max(node.history_maximum, peak);
    node.maximum = value;
    if (node.has_set) node.set_peak = @max(node.set_peak, peak) else {
        node.has_set = true;
        node.set_peak = peak;
    }
    node.set_value = value;
}

fn applySet(node: *Node, value: i64) void {
    node.history_maximum = @max(node.history_maximum, value);
    node.maximum = value;
    if (node.has_set) node.set_peak = @max(node.set_peak, value) else {
        node.has_set = true;
        node.set_peak = value;
    }
    node.set_value = value;
}

fn push(tree: *[TREE_SIZE]Node, node: usize) void {
    const parent = tree[node];
    if (parent.add != 0 or parent.add_peak != 0) {
        applyAddSummary(&tree[2 * node], parent.add, parent.add_peak);
        applyAddSummary(&tree[2 * node + 1], parent.add, parent.add_peak);
        tree[node].add = 0;
        tree[node].add_peak = 0;
    }
    if (parent.has_set) {
        applySetSummary(&tree[2 * node], parent.set_value, parent.set_peak);
        applySetSummary(&tree[2 * node + 1], parent.set_value, parent.set_peak);
        tree[node].has_set = false;
        tree[node].set_value = 0;
        tree[node].set_peak = 0;
    }
}

fn pull(tree: *[TREE_SIZE]Node, node: usize) void {
    tree[node].maximum = @max(tree[2 * node].maximum, tree[2 * node + 1].maximum);
    tree[node].history_maximum = @max(tree[2 * node].history_maximum, tree[2 * node + 1].history_maximum);
}

fn build(tree: *[TREE_SIZE]Node, input: [*c]const i64, offset: usize, node: usize, left: usize, right: usize) void {
    if (right - left == 1) {
        tree[node].maximum = input[offset + left];
        tree[node].history_maximum = input[offset + left];
        return;
    }
    const middle = left + (right - left) / 2;
    build(tree, input, offset, 2 * node, left, middle);
    build(tree, input, offset, 2 * node + 1, middle, right);
    pull(tree, node);
}

fn update(tree: *[TREE_SIZE]Node, node: usize, left: usize, right: usize,
    ql: usize, qr: usize, assignment: bool, value: i64) void {
    if (ql <= left and right <= qr) {
        if (assignment) applySet(&tree[node], value) else applyAdd(&tree[node], value);
        return;
    }
    push(tree, node);
    const middle = left + (right - left) / 2;
    if (ql < middle) update(tree, 2 * node, left, middle, ql, qr, assignment, value);
    if (middle < qr) update(tree, 2 * node + 1, middle, right, ql, qr, assignment, value);
    pull(tree, node);
}

fn query(tree: *[TREE_SIZE]Node, node: usize, left: usize, right: usize,
    ql: usize, qr: usize, history: bool) i64 {
    if (ql <= left and right <= qr) return if (history) tree[node].history_maximum else tree[node].maximum;
    push(tree, node);
    const middle = left + (right - left) / 2;
    var answer: i64 = -9223372036854775807 - 1;
    if (ql < middle) answer = query(tree, 2 * node, left, middle, ql, qr, history);
    if (middle < qr) answer = @max(answer, query(tree, 2 * node + 1, middle, right, ql, qr, history));
    return answer;
}

fn writeI64(output: [*c]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn segment_history_extreme(input: [*c]const i64, input_length: usize,
    output: [*c]u8, output_capacity: usize) i64 {
    if (input == null or input_length < 2 or input_length > MAX_INPUT) return -1;
    const n_value = input[0];
    const q_value = input[1];
    if (n_value < 1 or n_value > @as(i64, @intCast(MAX_N)) or q_value < 0 or q_value > @as(i64, @intCast(MAX_Q))) return -1;
    const n: usize = @intCast(n_value);
    const q: usize = @intCast(q_value);
    if (input_length != 2 + n + 4 * q) return -1;
    const operation_offset = 2 + n;
    for (0..n) |i| if (input[2 + i] < -VALUE_LIMIT or input[2 + i] > VALUE_LIMIT) return -1;
    for (0..q) |i| {
        const offset = operation_offset + 4 * i;
        const op = input[offset];
        const left = input[offset + 1];
        const right = input[offset + 2];
        const arg = input[offset + 3];
        if (op < 0 or op > 3 or left < 0 or right <= left or right > n_value) return -1;
        if ((op < 2 and (arg < -VALUE_LIMIT or arg > VALUE_LIMIT)) or (op >= 2 and arg != 0)) return -1;
    }

    var tree: [TREE_SIZE]Node = [_]Node{.{}} ** TREE_SIZE;
    var staged: [MAX_Q]i64 = [_]i64{0} ** MAX_Q;
    var answer_count: usize = 0;
    build(&tree, input, 2, 1, 0, n);
    for (0..q) |i| {
        const offset = operation_offset + 4 * i;
        const op: usize = @intCast(input[offset]);
        const left: usize = @intCast(input[offset + 1]);
        const right: usize = @intCast(input[offset + 2]);
        const arg = input[offset + 3];
        if (op < 2) update(&tree, 1, 0, n, left, right, op == 0, arg) else {
            staged[answer_count] = query(&tree, 1, 0, n, left, right, op == 3);
            answer_count += 1;
        }
    }
    const output_bytes = 8 * answer_count;
    if (output == null or output_capacity < output_bytes) return -2;
    for (0..answer_count) |i| writeI64(output, 8 * i, staged[i]);
    return @intCast(output_bytes);
}
