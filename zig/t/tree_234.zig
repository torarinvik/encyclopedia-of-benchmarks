const std = @import("std");

const MAX_OPERATIONS: usize = 128;
const MAX_NODES: usize = 2049;
const MAX_PARSEABLE_INPUT_LENGTH: usize = 258;
const MAX_OUTPUT_WORDS: usize = 130;
const NO_CHILD: usize = std.math.maxInt(usize);

const Node = struct {
    keys: [3]i64,
    children: [4]usize,
    key_count: usize,
    leaf: bool,
};

const Tree = struct {
    nodes: [MAX_NODES]Node,
    node_count: usize,
    root: usize,
    final_keys: [MAX_OPERATIONS]i64,
    final_count: usize,

    fn newNode(self: *Tree, leaf: bool) usize {
        const index = self.node_count;
        self.node_count += 1;
        self.nodes[index] = .{ .keys = .{ 0, 0, 0 }, .children = .{ NO_CHILD, NO_CHILD, NO_CHILD, NO_CHILD }, .key_count = 0, .leaf = leaf };
        return index;
    }

    fn contains(self: *const Tree, node_index: usize, key: i64) bool {
        if (node_index == NO_CHILD) return false;
        const node = self.nodes[node_index];
        var slot: usize = 0;
        while (slot < node.key_count and key > node.keys[slot]) : (slot += 1) {}
        if (slot < node.key_count and key == node.keys[slot]) return true;
        return !node.leaf and self.contains(node.children[slot], key);
    }

    fn splitChild(self: *Tree, parent_index: usize, child_slot: usize) void {
        const child_index = self.nodes[parent_index].children[child_slot];
        const child = self.nodes[child_index];
        const right_index = self.newNode(child.leaf);
        self.nodes[right_index].key_count = 1;
        self.nodes[right_index].keys[0] = child.keys[2];
        if (!child.leaf) {
            self.nodes[right_index].children[0] = child.children[2];
            self.nodes[right_index].children[1] = child.children[3];
        }
        self.nodes[child_index].key_count = 1;
        var slot = self.nodes[parent_index].key_count;
        while (slot > child_slot) : (slot -= 1) self.nodes[parent_index].keys[slot] = self.nodes[parent_index].keys[slot - 1];
        slot = self.nodes[parent_index].key_count + 1;
        while (slot > child_slot + 1) : (slot -= 1) self.nodes[parent_index].children[slot] = self.nodes[parent_index].children[slot - 1];
        self.nodes[parent_index].keys[child_slot] = child.keys[1];
        self.nodes[parent_index].children[child_slot + 1] = right_index;
        self.nodes[parent_index].key_count += 1;
    }

    fn insertNonfull(self: *Tree, node_index: usize, key: i64) void {
        if (self.nodes[node_index].leaf) {
            var slot = self.nodes[node_index].key_count;
            while (slot > 0 and key < self.nodes[node_index].keys[slot - 1]) : (slot -= 1) {
                self.nodes[node_index].keys[slot] = self.nodes[node_index].keys[slot - 1];
            }
            self.nodes[node_index].keys[slot] = key;
            self.nodes[node_index].key_count += 1;
            return;
        }
        var slot = self.nodes[node_index].key_count;
        while (slot > 0 and key < self.nodes[node_index].keys[slot - 1]) : (slot -= 1) {}
        var child_index = self.nodes[node_index].children[slot];
        if (self.nodes[child_index].key_count == 3) {
            self.splitChild(node_index, slot);
            if (key > self.nodes[node_index].keys[slot]) slot += 1;
            child_index = self.nodes[node_index].children[slot];
        }
        self.insertNonfull(child_index, key);
    }

    fn insert(self: *Tree, key: i64) void {
        if (self.contains(self.root, key)) return;
        if (self.root == NO_CHILD) {
            self.root = self.newNode(true);
            self.nodes[self.root].keys[0] = key;
            self.nodes[self.root].key_count = 1;
            return;
        }
        if (self.nodes[self.root].key_count == 3) {
            const old_root = self.root;
            self.root = self.newNode(false);
            self.nodes[self.root].children[0] = old_root;
            self.splitChild(self.root, 0);
        }
        self.insertNonfull(self.root, key);
    }

    fn predecessor(self: *const Tree, start: usize) i64 {
        var node_index = start;
        while (!self.nodes[node_index].leaf) node_index = self.nodes[node_index].children[self.nodes[node_index].key_count];
        return self.nodes[node_index].keys[self.nodes[node_index].key_count - 1];
    }

    fn successor(self: *const Tree, start: usize) i64 {
        var node_index = start;
        while (!self.nodes[node_index].leaf) node_index = self.nodes[node_index].children[0];
        return self.nodes[node_index].keys[0];
    }

    fn mergeChildren(self: *Tree, parent_index: usize, key_slot: usize) usize {
        const left_index = self.nodes[parent_index].children[key_slot];
        const right_index = self.nodes[parent_index].children[key_slot + 1];
        const left_count = self.nodes[left_index].key_count;
        const right_count = self.nodes[right_index].key_count;
        self.nodes[left_index].keys[left_count] = self.nodes[parent_index].keys[key_slot];
        for (0..right_count) |slot| self.nodes[left_index].keys[left_count + 1 + slot] = self.nodes[right_index].keys[slot];
        if (!self.nodes[left_index].leaf) {
            for (0..(right_count + 1)) |slot| self.nodes[left_index].children[left_count + 1 + slot] = self.nodes[right_index].children[slot];
        }
        self.nodes[left_index].key_count = left_count + 1 + right_count;
        const parent_count = self.nodes[parent_index].key_count;
        for (key_slot..(parent_count - 1)) |slot| self.nodes[parent_index].keys[slot] = self.nodes[parent_index].keys[slot + 1];
        for (key_slot + 1..parent_count) |slot| self.nodes[parent_index].children[slot] = self.nodes[parent_index].children[slot + 1];
        self.nodes[parent_index].key_count -= 1;
        return left_index;
    }

    fn borrowPrevious(self: *Tree, parent_index: usize, child_slot: usize) void {
        const child_index = self.nodes[parent_index].children[child_slot];
        const sibling_index = self.nodes[parent_index].children[child_slot - 1];
        const child_count = self.nodes[child_index].key_count;
        const sibling_count = self.nodes[sibling_index].key_count;
        var slot = child_count;
        while (slot > 0) : (slot -= 1) self.nodes[child_index].keys[slot] = self.nodes[child_index].keys[slot - 1];
        if (!self.nodes[child_index].leaf) {
            slot = child_count + 1;
            while (slot > 0) : (slot -= 1) self.nodes[child_index].children[slot] = self.nodes[child_index].children[slot - 1];
            self.nodes[child_index].children[0] = self.nodes[sibling_index].children[sibling_count];
        }
        self.nodes[child_index].keys[0] = self.nodes[parent_index].keys[child_slot - 1];
        self.nodes[parent_index].keys[child_slot - 1] = self.nodes[sibling_index].keys[sibling_count - 1];
        self.nodes[child_index].key_count += 1;
        self.nodes[sibling_index].key_count -= 1;
    }

    fn borrowNext(self: *Tree, parent_index: usize, child_slot: usize) void {
        const child_index = self.nodes[parent_index].children[child_slot];
        const sibling_index = self.nodes[parent_index].children[child_slot + 1];
        const child_count = self.nodes[child_index].key_count;
        const sibling_count = self.nodes[sibling_index].key_count;
        self.nodes[child_index].keys[child_count] = self.nodes[parent_index].keys[child_slot];
        if (!self.nodes[child_index].leaf) self.nodes[child_index].children[child_count + 1] = self.nodes[sibling_index].children[0];
        self.nodes[parent_index].keys[child_slot] = self.nodes[sibling_index].keys[0];
        for (0..(sibling_count - 1)) |slot| self.nodes[sibling_index].keys[slot] = self.nodes[sibling_index].keys[slot + 1];
        if (!self.nodes[sibling_index].leaf) {
            for (0..sibling_count) |slot| self.nodes[sibling_index].children[slot] = self.nodes[sibling_index].children[slot + 1];
        }
        self.nodes[child_index].key_count += 1;
        self.nodes[sibling_index].key_count -= 1;
    }

    fn removeFromNode(self: *Tree, node_index: usize, key: i64) void {
        var key_slot: usize = 0;
        while (key_slot < self.nodes[node_index].key_count and self.nodes[node_index].keys[key_slot] < key) : (key_slot += 1) {}
        const found = key_slot < self.nodes[node_index].key_count and self.nodes[node_index].keys[key_slot] == key;
        if (found) {
            if (self.nodes[node_index].leaf) {
                const count = self.nodes[node_index].key_count;
                for (key_slot..(count - 1)) |slot| self.nodes[node_index].keys[slot] = self.nodes[node_index].keys[slot + 1];
                self.nodes[node_index].key_count -= 1;
                return;
            }
            const left_index = self.nodes[node_index].children[key_slot];
            const right_index = self.nodes[node_index].children[key_slot + 1];
            if (self.nodes[left_index].key_count >= 2) {
                const replacement = self.predecessor(left_index);
                self.nodes[node_index].keys[key_slot] = replacement;
                self.removeFromNode(left_index, replacement);
            } else if (self.nodes[right_index].key_count >= 2) {
                const replacement = self.successor(right_index);
                self.nodes[node_index].keys[key_slot] = replacement;
                self.removeFromNode(right_index, replacement);
            } else {
                const merged = self.mergeChildren(node_index, key_slot);
                self.removeFromNode(merged, key);
            }
            return;
        }
        if (self.nodes[node_index].leaf) return;
        var child_slot = key_slot;
        var child_index = self.nodes[node_index].children[child_slot];
        if (self.nodes[child_index].key_count == 1) {
            if (child_slot > 0 and self.nodes[self.nodes[node_index].children[child_slot - 1]].key_count >= 2) {
                self.borrowPrevious(node_index, child_slot);
            } else if (child_slot < self.nodes[node_index].key_count and self.nodes[self.nodes[node_index].children[child_slot + 1]].key_count >= 2) {
                self.borrowNext(node_index, child_slot);
            } else if (child_slot < self.nodes[node_index].key_count) {
                child_index = self.mergeChildren(node_index, child_slot);
            } else {
                child_slot -= 1;
                child_index = self.mergeChildren(node_index, child_slot);
            }
        }
        self.removeFromNode(child_index, key);
    }

    fn remove(self: *Tree, key: i64) bool {
        if (!self.contains(self.root, key)) return false;
        const old_root = self.root;
        self.removeFromNode(old_root, key);
        if (self.nodes[old_root].key_count == 0) {
            self.root = if (self.nodes[old_root].leaf) NO_CHILD else self.nodes[old_root].children[0];
        }
        return true;
    }

    fn traverse(self: *Tree, node_index: usize) void {
        if (node_index == NO_CHILD) return;
        const node = self.nodes[node_index];
        for (0..node.key_count) |slot| {
            if (!node.leaf) self.traverse(node.children[slot]);
            self.final_keys[self.final_count] = node.keys[slot];
            self.final_count += 1;
        }
        if (!node.leaf) self.traverse(node.children[node.key_count]);
    }
};

fn writeI64Le(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(byte * 8));
}

export fn tree_234(input: ?[*]const i64, input_length: usize, output: ?[*]u8, capacity: usize) i64 {
    if (input == null or input_length == 0 or input_length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    const values = input.?;
    if (values[0] < 0 or values[0] > @as(i64, MAX_OPERATIONS)) return -1;
    const operation_count: usize = @intCast(values[0]);
    if (input_length != 1 + 2 * operation_count) return -1;
    for (0..operation_count) |operation| {
        const code = values[1 + 2 * operation];
        if (code != 0 and code != 1) return -1;
    }

    var tree = Tree{
        .nodes = undefined,
        .node_count = 0,
        .root = NO_CHILD,
        .final_keys = [_]i64{0} ** MAX_OPERATIONS,
        .final_count = 0,
    };
    var remove_results = [_]i64{0} ** MAX_OPERATIONS;
    var remove_count: usize = 0;
    for (0..operation_count) |operation| {
        const code = values[1 + 2 * operation];
        const key = values[2 + 2 * operation];
        if (code == 0) tree.insert(key) else {
            remove_results[remove_count] = if (tree.remove(key)) 1 else 0;
            remove_count += 1;
        }
    }
    tree.traverse(tree.root);

    var words = [_]i64{0} ** MAX_OUTPUT_WORDS;
    words[0] = @intCast(remove_count);
    @memcpy(words[1 .. 1 + remove_count], remove_results[0..remove_count]);
    words[1 + remove_count] = @intCast(tree.final_count);
    var word_count: usize = 2 + remove_count;
    for (tree.final_keys[0..tree.final_count]) |key| {
        words[word_count] = key;
        word_count += 1;
    }
    const output_bytes = word_count * 8;
    if (output_bytes > MAX_OUTPUT_WORDS * 8) return -1;
    if (output == null or capacity < output_bytes) return -2;
    const destination = output.?;
    for (words[0..word_count], 0..) |word, index| writeI64Le(destination, index * 8, word);
    return @intCast(output_bytes);
}
