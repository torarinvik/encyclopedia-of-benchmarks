const MAX_OPERATIONS: i64 = 64;
const MISSING: i64 = -129;
const NODE_CAPACITY: usize = 129;

const Tree = struct {
    left: [NODE_CAPACITY]usize = [_]usize{0} ** NODE_CAPACITY,
    right: [NODE_CAPACITY]usize = [_]usize{0} ** NODE_CAPACITY,
    size: [NODE_CAPACITY]usize = [_]usize{0} ** NODE_CAPACITY,
    free_next: [NODE_CAPACITY]usize = [_]usize{0} ** NODE_CAPACITY,
    key: [NODE_CAPACITY]i64 = [_]i64{0} ** NODE_CAPACITY,
    maximum: [NODE_CAPACITY]i64 = [_]i64{0} ** NODE_CAPACITY,
    next_node: usize = 1,
    free_head: usize = 0,

    fn allocate(self: *Tree) usize {
        var node: usize = undefined;
        if (self.free_head != 0) {
            node = self.free_head;
            self.free_head = self.free_next[node];
        } else {
            node = self.next_node;
            self.next_node += 1;
        }
        self.left[node] = 0; self.right[node] = 0; self.size[node] = 0;
        self.free_next[node] = 0; self.key[node] = 0; self.maximum[node] = 0;
        return node;
    }
    fn release(self: *Tree, node: usize) void {
        self.left[node] = 0; self.right[node] = 0; self.size[node] = 0;
        self.key[node] = 0; self.maximum[node] = 0;
        self.free_next[node] = self.free_head;
        self.free_head = node;
    }
    fn leaf(self: *Tree, value: i64) usize {
        const node = self.allocate();
        self.key[node] = value; self.maximum[node] = value; self.size[node] = 1;
        return node;
    }
    fn join(self: *Tree, a: usize, b: usize) usize {
        const node = self.allocate();
        self.left[node] = a; self.right[node] = b;
        self.size[node] = self.size[a] + self.size[b];
        self.maximum[node] = self.maximum[b];
        return node;
    }
    fn tooHeavy(a: usize, b: usize) bool { return a > 3 * b; }
    fn merge(self: *Tree, a: usize, b: usize) usize {
        if (a == 0) return b;
        if (b == 0) return a;
        if (tooHeavy(self.size[a], self.size[b])) {
            const x = self.left[a]; const y = self.right[a];
            self.release(a);
            const joined = self.join(x, self.merge(y, b));
            return self.rebalance(joined);
        }
        if (tooHeavy(self.size[b], self.size[a])) {
            const x = self.left[b]; const y = self.right[b];
            self.release(b);
            const joined = self.join(self.merge(a, x), y);
            return self.rebalance(joined);
        }
        return self.join(a, b);
    }
    fn rebalance(self: *Tree, node: usize) usize {
        if (self.size[node] == 1) return node;
        const a = self.left[node]; const b = self.right[node];
        if (tooHeavy(self.size[a], self.size[b]) or tooHeavy(self.size[b], self.size[a])) {
            self.release(node);
            return self.merge(a, b);
        }
        return node;
    }
    fn insert(self: *Tree, node: usize, value: i64) usize {
        if (node == 0) return self.leaf(value);
        if (self.size[node] == 1) {
            if (value <= self.key[node]) return self.join(self.leaf(value), node);
            return self.join(node, self.leaf(value));
        }
        const a = self.left[node];
        if (value <= self.maximum[a]) self.left[node] = self.insert(a, value)
        else self.right[node] = self.insert(self.right[node], value);
        self.size[node] = self.size[self.left[node]] + self.size[self.right[node]];
        self.maximum[node] = self.maximum[self.right[node]];
        return self.rebalance(node);
    }
    fn remove(self: *Tree, node: usize, value: i64, removed: *bool) usize {
        removed.* = false;
        if (node == 0) return 0;
        if (self.size[node] == 1) {
            if (self.key[node] != value) return node;
            self.release(node); removed.* = true; return 0;
        }
        if (value <= self.maximum[self.left[node]]) self.left[node] = self.remove(self.left[node], value, removed)
        else self.right[node] = self.remove(self.right[node], value, removed);
        if (!removed.*) return node;
        const a = self.left[node]; const b = self.right[node];
        if (a == 0 or b == 0) {
            const child = if (a != 0) a else b;
            self.release(node);
            return child;
        }
        self.size[node] = self.size[a] + self.size[b];
        self.maximum[node] = self.maximum[b];
        return self.rebalance(node);
    }
    fn rank(self: *const Tree, node: usize, value: i64) i64 {
        if (node == 0) return 0;
        if (self.size[node] == 1) return if (self.key[node] < value) 1 else 0;
        const a = self.left[node];
        if (value <= self.maximum[a]) return self.rank(a, value);
        return @intCast(self.size[a]) + self.rank(self.right[node], value);
    }
    fn kth(self: *const Tree, node_input: usize, index_input: i64) i64 {
        if (node_input == 0 or index_input >= @as(i64, @intCast(self.size[node_input]))) return MISSING;
        var node = node_input;
        var index = index_input;
        while (self.size[node] != 1) {
            const a = self.left[node];
            if (index < @as(i64, @intCast(self.size[a]))) node = a
            else { index -= @intCast(self.size[a]); node = self.right[node]; }
        }
        return self.key[node];
    }
    fn predecessor(self: *const Tree, node: usize, value: i64) i64 {
        if (node == 0) return MISSING;
        if (self.size[node] == 1) return if (self.key[node] < value) self.key[node] else MISSING;
        const a = self.left[node];
        if (value <= self.maximum[a]) return self.predecessor(a, value);
        const answer = self.predecessor(self.right[node], value);
        return if (answer == MISSING) self.maximum[a] else answer;
    }
    fn successor(self: *const Tree, node: usize, value: i64) i64 {
        if (node == 0) return MISSING;
        if (self.size[node] == 1) return if (self.key[node] > value) self.key[node] else MISSING;
        const a = self.left[node];
        return if (value < self.maximum[a]) self.successor(a, value) else self.successor(self.right[node], value);
    }
};

export fn weight_balanced_leaf_tree_order_statistics(input: ?[*]const i64, length: usize) i64 {
    if (input == null or length < 1 or length > 130) return -1;
    const values = input.?[0..length];
    const q = values[0];
    if (q < 0 or q > MAX_OPERATIONS or length != @as(usize, @intCast(1 + 2 * q))) return -1;
    for (0..@intCast(q)) |i| {
        const op = values[1 + 2 * i]; const arg = values[2 + 2 * i];
        if (op < 0 or op > 5) return -1;
        if (op == 3) { if (arg < 0 or arg >= MAX_OPERATIONS) return -1; }
        else if (arg < -128 or arg > 127) return -1;
    }
    var tree = Tree{};
    var root: usize = 0;
    var checksum: i64 = 0;
    for (0..@intCast(q)) |i| {
        const op = values[1 + 2 * i]; const arg = values[2 + 2 * i];
        if (op == 0) root = tree.insert(root, arg)
        else if (op == 1) { var removed = false; root = tree.remove(root, arg, &removed); }
        else {
            const answer = if (op == 2) tree.rank(root, arg)
                else if (op == 3) tree.kth(root, arg)
                else if (op == 4) tree.predecessor(root, arg)
                else tree.successor(root, arg);
            checksum += (@as(i64, @intCast(i)) + 1) * (answer - MISSING);
        }
    }
    return checksum;
}
