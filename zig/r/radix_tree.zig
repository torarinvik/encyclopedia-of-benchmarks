const std = @import("std");

const MAX_OPERATIONS: usize = 256;
const MAX_WORD_LENGTH: usize = 32;
const MAX_ROOT_PREFIX_LENGTH: usize = MAX_OPERATIONS * MAX_WORD_LENGTH;
const MAX_NODES: usize = 1 + 2 * MAX_OPERATIONS;
const MAX_VALID_INPUT_LENGTH: usize = 8705;
const MAX_PARSEABLE_INPUT_LENGTH: usize = 8706;

const Node = struct {
    prefix: [MAX_WORD_LENGTH]u8 = @splat(0),
    prefix_len: usize = 0,
    children: [26]u16 = @splat(0),
    is_leaf: bool = false,
};

fn allocateNode(nodes: *[MAX_NODES]Node, node_count: *usize, prefix: []const u8, is_leaf: bool) usize {
    if (node_count.* >= MAX_NODES) return 0;
    const index = node_count.*;
    node_count.* += 1;
    @memcpy(nodes[index].prefix[0..prefix.len], prefix);
    nodes[index].prefix_len = prefix.len;
    nodes[index].is_leaf = is_leaf;
    return index;
}

fn insertWord(nodes: *[MAX_NODES]Node, node_count: *usize, root_prefix: *[MAX_ROOT_PREFIX_LENGTH]u8, root_prefix_len: usize, node_index: usize, word: []const u8) bool {
    if (word.len == 0) { nodes[node_index].is_leaf = true; return true; }
    const prefix_len = nodes[node_index].prefix_len;
    const equal_prefix = if (node_index == 0) root_prefix_len == word.len and std.mem.eql(u8, root_prefix[0..root_prefix_len], word) else prefix_len == word.len and std.mem.eql(u8, nodes[node_index].prefix[0..prefix_len], word);
    if (equal_prefix and !nodes[node_index].is_leaf) {
        nodes[node_index].is_leaf = true;
        return true;
    }
    const letter: usize = @intCast(word[0] - 'a');
    const encoded_child = nodes[node_index].children[letter];
    if (encoded_child == 0) {
        const child = allocateNode(nodes, node_count, word, true);
        if (child == 0) return false;
        nodes[node_index].children[letter] = @intCast(child + 1);
        return true;
    }
    const child: usize = @as(usize, encoded_child) - 1;
    const child_prefix_len = nodes[child].prefix_len;
    var common: usize = 0;
    while (common < child_prefix_len and common < word.len and nodes[child].prefix[common] == word[common]) : (common += 1) {}
    if (common == child_prefix_len) return insertWord(nodes, node_count, root_prefix, root_prefix_len, child, word[common..]);

    var old_suffix: [MAX_WORD_LENGTH]u8 = @splat(0);
    const old_suffix_len = child_prefix_len - common;
    @memcpy(old_suffix[0..old_suffix_len], nodes[child].prefix[common..child_prefix_len]);
    const intermediate = allocateNode(nodes, node_count, word[0..common], false);
    if (intermediate == 0) return false;
    @memcpy(nodes[child].prefix[0..old_suffix_len], old_suffix[0..old_suffix_len]);
    nodes[child].prefix_len = old_suffix_len;
    const old_letter: usize = @intCast(old_suffix[0] - 'a');
    nodes[intermediate].children[old_letter] = @intCast(child + 1);
    nodes[node_index].children[letter] = @intCast(intermediate + 1);
    if (common == word.len) { nodes[intermediate].is_leaf = true; return true; }
    return insertWord(nodes, node_count, root_prefix, root_prefix_len, intermediate, word[common..]);
}

fn findWord(nodes: *const [MAX_NODES]Node, node_index: usize, word: []const u8) bool {
    if (word.len == 0) return false;
    const letter: usize = @intCast(word[0] - 'a');
    const encoded_child = nodes[node_index].children[letter];
    if (encoded_child == 0) return false;
    const child: usize = @as(usize, encoded_child) - 1;
    const prefix_len = nodes[child].prefix_len;
    var common: usize = 0;
    while (common < prefix_len and common < word.len and nodes[child].prefix[common] == word[common]) : (common += 1) {}
    if (common != prefix_len) return false;
    if (common == word.len) return nodes[child].is_leaf;
    return findWord(nodes, child, word[common..]);
}

fn deleteWord(nodes: *[MAX_NODES]Node, root_prefix: *[MAX_ROOT_PREFIX_LENGTH]u8, root_prefix_len: *usize, node_index: usize, word: []const u8) bool {
    if (word.len == 0) return false;
    const letter: usize = @intCast(word[0] - 'a');
    const encoded_child = nodes[node_index].children[letter];
    if (encoded_child == 0) return false;
    const child: usize = @as(usize, encoded_child) - 1;
    const prefix_len = nodes[child].prefix_len;
    var common: usize = 0;
    while (common < prefix_len and common < word.len and nodes[child].prefix[common] == word[common]) : (common += 1) {}
    if (common != prefix_len) return false;
    if (common != word.len) return deleteWord(nodes, root_prefix, root_prefix_len, child, word[common..]);
    if (!nodes[child].is_leaf) return false;

    var child_count: usize = 0;
    for (nodes[child].children) |entry| { if (entry != 0) child_count += 1; }
    if (child_count == 0) {
        nodes[node_index].children[letter] = 0;
        var remaining: usize = 0;
        var survivor: usize = 0;
        for (nodes[node_index].children) |entry| {
            if (entry != 0) { remaining += 1; survivor = @as(usize, entry) - 1; }
        }
        if (remaining == 1 and !nodes[node_index].is_leaf) {
            const survivor_len = nodes[survivor].prefix_len;
            if (node_index == 0) {
                if (root_prefix_len.* + survivor_len > MAX_ROOT_PREFIX_LENGTH) return false;
                @memcpy(root_prefix[root_prefix_len.* .. root_prefix_len.* + survivor_len], nodes[survivor].prefix[0..survivor_len]);
                root_prefix_len.* += survivor_len;
            } else {
                const parent_len = nodes[node_index].prefix_len;
                @memcpy(nodes[node_index].prefix[parent_len .. parent_len + survivor_len], nodes[survivor].prefix[0..survivor_len]);
                nodes[node_index].prefix_len += survivor_len;
            }
            nodes[node_index].is_leaf = nodes[survivor].is_leaf;
            nodes[node_index].children = nodes[survivor].children;
        }
    } else if (child_count > 1) {
        nodes[child].is_leaf = false;
    } else {
        var survivor: usize = 0;
        for (nodes[child].children) |entry| { if (entry != 0) { survivor = @as(usize, entry) - 1; break; } }
        const survivor_len = nodes[survivor].prefix_len;
        const child_len = nodes[child].prefix_len;
        @memcpy(nodes[child].prefix[child_len .. child_len + survivor_len], nodes[survivor].prefix[0..survivor_len]);
        nodes[child].prefix_len += survivor_len;
        nodes[child].is_leaf = nodes[survivor].is_leaf;
        nodes[child].children = nodes[survivor].children;
    }
    return true;
}

export fn radix_tree_benchmark(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length < 1 or length > MAX_PARSEABLE_INPUT_LENGTH or length > MAX_VALID_INPUT_LENGTH) return -1;
    const input = input_opt.?;
    if (input[0] < 0 or input[0] > MAX_OPERATIONS) return -1;
    const operation_count: usize = @intCast(input[0]);
    var nodes: [MAX_NODES]Node = @splat(.{});
    var node_count: usize = 1;
    var root_prefix: [MAX_ROOT_PREFIX_LENGTH]u8 = @splat(0);
    var root_prefix_len: usize = 0;
    var checksum: i64 = 0;
    var cursor: usize = 1;
    for (0..operation_count) |operation| {
        if (cursor + 2 > length) return -1;
        const opcode = input[cursor];
        const word_length_value = input[cursor + 1];
        cursor += 2;
        if (opcode < 0 or opcode > 2 or word_length_value < 1 or word_length_value > MAX_WORD_LENGTH) return -1;
        const word_length: usize = @intCast(word_length_value);
        if (cursor + word_length > length) return -1;
        var word: [MAX_WORD_LENGTH]u8 = @splat(0);
        for (0..word_length) |index| {
            const byte = input[cursor + index];
            if (byte < 97 or byte > 122) return -1;
            word[index] = @intCast(byte);
        }
        cursor += word_length;
        if (opcode == 0) {
            if (!insertWord(&nodes, &node_count, &root_prefix, root_prefix_len, 0, word[0..word_length])) return -1;
        } else {
            const observed = if (opcode == 1) findWord(&nodes, 0, word[0..word_length]) else deleteWord(&nodes, &root_prefix, &root_prefix_len, 0, word[0..word_length]);
            checksum += (@as(i64, @intCast(operation)) + 1) * (1 + @as(i64, @intFromBool(observed)));
        }
    }
    if (cursor != length) return -1;
    return checksum;
}
