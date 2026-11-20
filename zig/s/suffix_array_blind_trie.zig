const std = @import("std");

const MAX_TEXT_LENGTH: usize = 32;
const MAX_INPUT_LENGTH: usize = 34;
const MAX_NODES: usize = 64;

const TrieNode = struct {
    is_leaf: bool = false,
    split_pos: i32 = 0,
    leaf_start: i32 = -1,
    edge_symbol: i32 = 0,
    first_child: i32 = -1,
    next_sibling: i32 = -1,
};

const BlindTrie = struct {
    node: [MAX_NODES]TrieNode,
    count: i32,
    root: i32,
};

fn symbolAt(input: []const i64, n: i32, start: i32, depth: i32) i32 {
    const position = start + depth;
    if (position >= n) return 0;
    return @as(i32, @intCast(input[@intCast(position + 1)])) + 1;
}

fn commonPrefix(input: []const i64, n: i32, left: i32, right: i32) i32 {
    var depth: i32 = 0;
    while (symbolAt(input, n, left, depth) == symbolAt(input, n, right, depth)) {
        depth += 1;
    }
    return depth;
}

fn newNode(trie: *BlindTrie, is_leaf: bool, value: i32) i32 {
    const index = trie.count;
    trie.count += 1;
    trie.node[@intCast(index)].is_leaf = is_leaf;
    trie.node[@intCast(index)].split_pos = if (is_leaf) 0 else value;
    trie.node[@intCast(index)].leaf_start = if (is_leaf) value else -1;
    trie.node[@intCast(index)].first_child = -1;
    trie.node[@intCast(index)].next_sibling = -1;
    return index;
}

fn findChild(trie: *const BlindTrie, parent: i32, symbol: i32) i32 {
    var child = trie.node[@intCast(parent)].first_child;
    while (child >= 0) {
        const item = trie.node[@intCast(child)];
        if (item.edge_symbol == symbol) return child;
        if (item.edge_symbol > symbol) return -1;
        child = item.next_sibling;
    }
    return -1;
}

fn linkChild(trie: *BlindTrie, parent: i32, child: i32) void {
    const symbol = trie.node[@intCast(child)].edge_symbol;
    var previous: i32 = -1;
    var cursor = trie.node[@intCast(parent)].first_child;
    while (cursor >= 0 and trie.node[@intCast(cursor)].edge_symbol < symbol) {
        previous = cursor;
        cursor = trie.node[@intCast(cursor)].next_sibling;
    }
    trie.node[@intCast(child)].next_sibling = cursor;
    if (previous < 0) {
        trie.node[@intCast(parent)].first_child = child;
    } else {
        trie.node[@intCast(previous)].next_sibling = child;
    }
}

fn replaceChild(trie: *BlindTrie, parent: i32, old_child: i32, new_child: i32) void {
    var previous: i32 = -1;
    var cursor = trie.node[@intCast(parent)].first_child;
    while (cursor != old_child) {
        previous = cursor;
        cursor = trie.node[@intCast(cursor)].next_sibling;
    }
    trie.node[@intCast(new_child)].edge_symbol = trie.node[@intCast(old_child)].edge_symbol;
    trie.node[@intCast(new_child)].next_sibling = trie.node[@intCast(old_child)].next_sibling;
    if (previous < 0) {
        trie.node[@intCast(parent)].first_child = new_child;
    } else {
        trie.node[@intCast(previous)].next_sibling = new_child;
    }
}

fn insertSuffix(trie: *BlindTrie, input: []const i64, n: i32, start: i32) void {
    const fresh = newNode(trie, true, start);
    if (trie.node[@intCast(trie.root)].is_leaf) {
        const old = trie.root;
        const depth = commonPrefix(input, n, trie.node[@intCast(old)].leaf_start, start);
        const middle = newNode(trie, false, depth);
        trie.node[@intCast(old)].edge_symbol = symbolAt(input, n, trie.node[@intCast(old)].leaf_start, depth);
        trie.node[@intCast(fresh)].edge_symbol = symbolAt(input, n, start, depth);
        linkChild(trie, middle, old);
        linkChild(trie, middle, fresh);
        trie.root = middle;
        return;
    }

    var leaf = trie.root;
    while (!trie.node[@intCast(leaf)].is_leaf) {
        const symbol = symbolAt(input, n, start, trie.node[@intCast(leaf)].split_pos);
        var child = findChild(trie, leaf, symbol);
        if (child < 0) child = trie.node[@intCast(leaf)].first_child;
        leaf = child;
    }
    const old_start = trie.node[@intCast(leaf)].leaf_start;
    const depth = commonPrefix(input, n, start, old_start);
    var parent: i32 = -1;
    var current = trie.root;
    while (!trie.node[@intCast(current)].is_leaf
        and trie.node[@intCast(current)].split_pos < depth)
    {
        const symbol = symbolAt(input, n, start, trie.node[@intCast(current)].split_pos);
        var child = findChild(trie, current, symbol);
        if (child < 0) child = trie.node[@intCast(current)].first_child;
        parent = current;
        current = child;
    }
    if (!trie.node[@intCast(current)].is_leaf
        and trie.node[@intCast(current)].split_pos == depth)
    {
        trie.node[@intCast(fresh)].edge_symbol = symbolAt(input, n, start, depth);
        linkChild(trie, current, fresh);
        return;
    }

    const middle = newNode(trie, false, depth);
    if (parent < 0) {
        trie.root = middle;
    } else {
        replaceChild(trie, parent, current, middle);
    }
    trie.node[@intCast(current)].edge_symbol = symbolAt(input, n, old_start, depth);
    trie.node[@intCast(fresh)].edge_symbol = symbolAt(input, n, start, depth);
    linkChild(trie, middle, current);
    linkChild(trie, middle, fresh);
}

fn orderedLeaves(trie: *const BlindTrie, output: []i32) usize {
    var stack: [MAX_NODES]i32 = undefined;
    var top: usize = 1;
    var count: usize = 0;
    stack[0] = trie.root;
    while (top > 0) {
        top -= 1;
        const node = stack[top];
        if (trie.node[@intCast(node)].is_leaf) {
            output[count] = trie.node[@intCast(node)].leaf_start;
            count += 1;
            continue;
        }
        var children: [MAX_TEXT_LENGTH]i32 = undefined;
        var child_count: usize = 0;
        var child = trie.node[@intCast(node)].first_child;
        while (child >= 0) {
            children[child_count] = child;
            child_count += 1;
            child = trie.node[@intCast(child)].next_sibling;
        }
        while (child_count > 0) {
            child_count -= 1;
            stack[top] = children[child_count];
            top += 1;
        }
    }
    return count;
}

fn storeI64Le(output: []u8, offset: usize, value: i32) void {
    const bits: u64 = @intCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(byte * 8));
}

export fn suffix_array_blind_trie(
    values: ?[*]const i64,
    length: usize,
    output: ?[*]u8,
    capacity: usize,
) i64 {
    if (values == null or length < 1 or length > MAX_INPUT_LENGTH) return -1;
    const input = values.?[0..length];
    const count_value = input[0];
    if (count_value < 0 or count_value > MAX_TEXT_LENGTH) return -1;
    const n: usize = @intCast(count_value);
    if (length != n + 1) return -1;
    for (input[1..]) |value| if (value < 0 or value > 255) return -1;
    const output_bytes = n * 8;
    if (output == null or capacity < output_bytes) return -2;
    if (n == 0) return 0;

    var trie: BlindTrie = std.mem.zeroes(BlindTrie);
    for (&trie.node) |*node| {
        node.first_child = -1;
        node.next_sibling = -1;
        node.leaf_start = -1;
    }
    trie.root = newNode(&trie, true, 0);
    for (1..n) |start| insertSuffix(&trie, input, @intCast(n), @intCast(start));
    var order: [MAX_TEXT_LENGTH]i32 = undefined;
    const order_count = orderedLeaves(&trie, order[0..]);
    const out = output.?[0..output_bytes];
    for (0..order_count) |index| storeI64Le(out, index * 8, order[index]);
    return @intCast(output_bytes);
}
