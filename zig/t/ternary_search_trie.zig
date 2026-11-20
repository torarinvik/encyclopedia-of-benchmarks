const MAX_OPERATIONS: usize = 64;
const MAX_KEY_LENGTH: usize = 6;
const RECORD_WIDTH: usize = 9;
const MAX_INPUT_VALUES: usize = 577;
const MAX_PARSEABLE_INPUT_VALUES: usize = 578;
const MAX_NODES: usize = 384;

const Node = struct {
    character: i64 = 0,
    left: usize = 0,
    middle: usize = 0,
    right: usize = 0,
    value: i64 = 0,
    present: bool = false,
};

fn putNode(nodes: *[MAX_NODES + 1]Node, node_id: usize,
           key: *const [MAX_KEY_LENGTH]i64, length: usize, depth: usize,
           value: i64, old_value: *i64, size: *usize, node_count: *usize) usize {
    var current = node_id;
    if (current == 0) {
        node_count.* += 1;
        current = node_count.*;
        nodes[current].character = key[depth];
    }
    if (key[depth] < nodes[current].character) {
        nodes[current].left = putNode(nodes, nodes[current].left, key, length,
            depth, value, old_value, size, node_count);
    } else if (key[depth] > nodes[current].character) {
        nodes[current].right = putNode(nodes, nodes[current].right, key, length,
            depth, value, old_value, size, node_count);
    } else if (depth + 1 < length) {
        nodes[current].middle = putNode(nodes, nodes[current].middle, key, length,
            depth + 1, value, old_value, size, node_count);
    } else {
        old_value.* = if (nodes[current].present) nodes[current].value else 0;
        if (!nodes[current].present) size.* += 1;
        nodes[current].value = value;
        nodes[current].present = true;
    }
    return current;
}

fn findNode(nodes: *const [MAX_NODES + 1]Node, node_id: usize,
            key: *const [MAX_KEY_LENGTH]i64, length: usize) usize {
    var current = node_id;
    var depth: usize = 0;
    while (current != 0) {
        if (key[depth] < nodes[current].character) {
            current = nodes[current].left;
        } else if (key[depth] > nodes[current].character) {
            current = nodes[current].right;
        } else if (depth + 1 == length) {
            return current;
        } else {
            current = nodes[current].middle;
            depth += 1;
        }
    }
    return 0;
}

fn deleteNode(nodes: *[MAX_NODES + 1]Node, node_id: usize,
              key: *const [MAX_KEY_LENGTH]i64, length: usize, depth: usize,
              removed: *i64, size: *usize) usize {
    if (node_id == 0) return 0;
    if (key[depth] < nodes[node_id].character) {
        nodes[node_id].left = deleteNode(nodes, nodes[node_id].left, key, length,
            depth, removed, size);
    } else if (key[depth] > nodes[node_id].character) {
        nodes[node_id].right = deleteNode(nodes, nodes[node_id].right, key, length,
            depth, removed, size);
    } else if (depth + 1 < length) {
        nodes[node_id].middle = deleteNode(nodes, nodes[node_id].middle, key, length,
            depth + 1, removed, size);
    } else if (nodes[node_id].present) {
        removed.* = nodes[node_id].value;
        nodes[node_id].value = 0;
        nodes[node_id].present = false;
        size.* -= 1;
    }
    const node = nodes[node_id];
    if (!node.present and node.left == 0 and node.middle == 0 and node.right == 0)
        return 0;
    return node_id;
}

fn countNodes(nodes: *const [MAX_NODES + 1]Node, node_id: usize) usize {
    if (node_id == 0) return 0;
    const node = nodes[node_id];
    return @as(usize, @intFromBool(node.present)) + countNodes(nodes, node.left) +
        countNodes(nodes, node.middle) + countNodes(nodes, node.right);
}

fn countMatches(nodes: *const [MAX_NODES + 1]Node, node_id: usize,
                pattern: *const [MAX_KEY_LENGTH]i64, length: usize, depth: usize) usize {
    if (node_id == 0) return 0;
    const node = nodes[node_id];
    const token = pattern[depth];
    if (token == 46) {
        const here = if (depth + 1 == length) @as(usize, @intFromBool(node.present))
                     else countMatches(nodes, node.middle, pattern, length, depth + 1);
        return countMatches(nodes, node.left, pattern, length, depth) + here +
            countMatches(nodes, node.right, pattern, length, depth);
    }
    if (token < node.character)
        return countMatches(nodes, node.left, pattern, length, depth);
    if (token > node.character)
        return countMatches(nodes, node.right, pattern, length, depth);
    if (depth + 1 == length) return @as(usize, @intFromBool(node.present));
    return countMatches(nodes, node.middle, pattern, length, depth + 1);
}

fn validInput(input: [*c]const i64, length: usize) ?usize {
    if (input == null or length < 1 or length > MAX_PARSEABLE_INPUT_VALUES) return null;
    if (input[0] < 0 or input[0] > MAX_OPERATIONS) return null;
    const operation_count: usize = @intCast(input[0]);
    if (length != 1 + operation_count * RECORD_WIDTH) return null;
    for (0..operation_count) |operation| {
        const base = 1 + operation * RECORD_WIDTH;
        const opcode = input[base];
        const key_length = input[base + 1];
        if (opcode < 0 or opcode > 6 or key_length < 0 or key_length > MAX_KEY_LENGTH) return null;
        if ((opcode <= 2 and key_length == 0) or (opcode == 6 and key_length != 0)) return null;
        for (0..MAX_KEY_LENGTH) |index| {
            const character = input[base + 2 + index];
            if (index < key_length) {
                if (!((character >= 97 and character <= 122) or
                    (opcode == 5 and character == 46))) return null;
            } else if (character != 0) return null;
        }
        const value = input[base + RECORD_WIDTH - 1];
        if (opcode == 0) {
            if (value < 1 or value > 65535) return null;
        } else if (value != 0) return null;
    }
    return operation_count;
}

export fn ternary_search_trie(input: [*c]const i64, length: usize) i64 {
    const operation_count = validInput(input, length) orelse return -1;
    var nodes: [MAX_NODES + 1]Node = @splat(.{});
    var node_count: usize = 0;
    var root: usize = 0;
    var size: usize = 0;
    var total: i64 = 0;
    for (0..operation_count) |operation| {
        const base = 1 + operation * RECORD_WIDTH;
        const opcode = input[base];
        const key_length: usize = @intCast(input[base + 1]);
        var key: [MAX_KEY_LENGTH]i64 = @splat(0);
        for (0..MAX_KEY_LENGTH) |index| key[index] = input[base + 2 + index];
        const value = input[base + RECORD_WIDTH - 1];
        var observed: i64 = 0;
        if (opcode == 0) {
            root = putNode(&nodes, root, &key, key_length, 0, value,
                &observed, &size, &node_count);
        } else if (opcode == 1) {
            const found = findNode(&nodes, root, &key, key_length);
            if (found != 0 and nodes[found].present) observed = nodes[found].value;
        } else if (opcode == 2) {
            root = deleteNode(&nodes, root, &key, key_length, 0, &observed, &size);
        } else if (opcode == 3) {
            var current = root;
            var depth: usize = 0;
            while (current != 0 and depth < key_length) {
                const node = nodes[current];
                if (key[depth] < node.character) current = node.left
                else if (key[depth] > node.character) current = node.right
                else {
                    depth += 1;
                    if (node.present) observed = @intCast(depth);
                    current = node.middle;
                }
            }
        } else if (opcode == 4) {
            if (key_length == 0) {
                observed = @intCast(size);
            } else {
                const found = findNode(&nodes, root, &key, key_length);
                if (found != 0)
                    observed = @as(i64, @intFromBool(nodes[found].present)) +
                        @as(i64, @intCast(countNodes(&nodes, nodes[found].middle)));
            }
        } else if (opcode == 5 and key_length != 0) {
            observed = @intCast(countMatches(&nodes, root, &key, key_length, 0));
        } else if (opcode == 6) {
            observed = @intCast(size);
        }
        total += @as(i64, @intCast(operation + 1)) * observed;
    }
    return total;
}
