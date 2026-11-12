const max_q: usize = 64;
const max_bits: usize = 30;
const max_nodes: usize = 1 + max_bits * max_q;
const max_input_values: usize = 1 + 2 * max_q;

const Trie = struct {
    children: [max_nodes][2]i32,
    count: [max_nodes]i32,
    node_count: usize,
};

fn findOrCreateChild(trie: *Trie, node: usize, direction: usize) usize {
    var child = trie.children[node][direction];
    if (child < 0) {
        child = @intCast(trie.node_count);
        trie.node_count += 1;
        trie.children[@intCast(child)] = .{ -1, -1 };
        trie.children[node][direction] = child;
    }
    return @intCast(child);
}

fn insertValue(trie: *Trie, value: u32) void {
    var path: [max_bits + 1]usize = undefined;
    path[0] = 0;
    var node: usize = 0;
    for (0..max_bits) |depth| {
        const bit = max_bits - 1 - depth;
        node = findOrCreateChild(trie, node, @intCast((value >> @intCast(bit)) & 1));
        path[depth + 1] = node;
    }
    if (trie.count[node] != 0) return;
    for (path) |item| trie.count[item] += 1;
}

fn removeValue(trie: *Trie, value: u32) void {
    var path: [max_bits + 1]usize = undefined;
    path[0] = 0;
    var node: usize = 0;
    for (0..max_bits) |depth| {
        const bit = max_bits - 1 - depth;
        const child = trie.children[node][@intCast((value >> @intCast(bit)) & 1)];
        if (child < 0) return;
        node = @intCast(child);
        path[depth + 1] = node;
    }
    if (trie.count[node] == 0) return;
    for (path) |item| trie.count[item] -= 1;
}

fn minimumXor(trie: *const Trie, value: u32) u32 {
    var node: usize = 0;
    var result: u32 = 0;
    var bit: usize = max_bits;
    while (bit > 0) {
        bit -= 1;
        const preferred: usize = @intCast((value >> @intCast(bit)) & 1);
        const child = trie.children[node][preferred];
        if (child >= 0 and trie.count[@intCast(child)] > 0) {
            node = @intCast(child);
        } else {
            result |= @as(u32, 1) << @intCast(bit);
            node = @intCast(trie.children[node][preferred ^ 1]);
        }
    }
    return result;
}

fn storeI64Le(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn set_xor_min(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 3 or length > max_input_values) return -1;
    const input = input_opt.?;
    const q_value = input[0];
    if (q_value < 1 or q_value > 64) return -1;
    const q: usize = @intCast(q_value);
    if (length != 1 + 2 * q) return -1;
    for (0..q) |operation| {
        const offset = 1 + 2 * operation;
        if (input[offset] < 0 or input[offset] > 2 or input[offset + 1] < 0 or
            input[offset + 1] >= (@as(i64, 1) << max_bits)) return -1;
    }

    var trie: Trie = undefined;
    trie.node_count = 1;
    for (0..max_nodes) |node| {
        trie.children[node] = .{ -1, -1 };
        trie.count[node] = 0;
    }
    var answers: [max_q]i64 = undefined;
    var answer_count: usize = 0;
    for (0..q) |operation| {
        const offset = 1 + 2 * operation;
        const kind = input[offset];
        const value: u32 = @intCast(input[offset + 1]);
        if (kind == 0) {
            insertValue(&trie, value);
        } else if (kind == 1) {
            removeValue(&trie, value);
        } else {
            if (trie.count[0] == 0) return -1;
            answers[answer_count] = @intCast(minimumXor(&trie, value));
            answer_count += 1;
        }
    }

    const required = 8 * answer_count;
    if (output_opt == null or capacity < required) return -2;
    const output = output_opt.?;
    for (0..answer_count) |index| storeI64Le(output, 8 * index, answers[index]);
    return @intCast(required);
}
