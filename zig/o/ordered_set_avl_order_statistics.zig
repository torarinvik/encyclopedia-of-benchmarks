const MAX_ITEMS: i64 = 32;
const MAX_OPS: i64 = 32;
const MAX_KEY: i64 = 1000;

const Tree = struct {
    key: [65]i64 = [_]i64{0} ** 65,
    height: [65]i32 = [_]i32{0} ** 65,
    size: [65]i64 = [_]i64{0} ** 65,
    left: [65]usize = [_]usize{0} ** 65,
    right: [65]usize = [_]usize{0} ** 65,
    used: usize = 0,

    fn nodeHeight(self: *const Tree, node: usize) i32 { return if (node == 0) 0 else self.height[node]; }
    fn nodeSize(self: *const Tree, node: usize) i64 { return if (node == 0) 0 else self.size[node]; }
    fn refresh(self: *Tree, node: usize) void {
        const lh = self.nodeHeight(self.left[node]);
        const rh = self.nodeHeight(self.right[node]);
        self.height[node] = @max(lh, rh) + 1;
        self.size[node] = self.nodeSize(self.left[node]) + self.nodeSize(self.right[node]) + 1;
    }
    fn rotateRight(self: *Tree, root: usize) usize {
        const pivot = self.left[root];
        self.left[root] = self.right[pivot]; self.right[pivot] = root;
        self.refresh(root); self.refresh(pivot); return pivot;
    }
    fn rotateLeft(self: *Tree, root: usize) usize {
        const pivot = self.right[root];
        self.right[root] = self.left[pivot]; self.left[pivot] = root;
        self.refresh(root); self.refresh(pivot); return pivot;
    }
    fn rebalance(self: *Tree, root: usize) usize {
        self.refresh(root);
        const difference = self.nodeHeight(self.left[root]) - self.nodeHeight(self.right[root]);
        if (difference > 1) {
            const child = self.left[root];
            if (self.nodeHeight(self.left[child]) < self.nodeHeight(self.right[child])) self.left[root] = self.rotateLeft(child);
            return self.rotateRight(root);
        }
        if (difference < -1) {
            const child = self.right[root];
            if (self.nodeHeight(self.right[child]) < self.nodeHeight(self.left[child])) self.right[root] = self.rotateRight(child);
            return self.rotateLeft(root);
        }
        return root;
    }
    fn insert(self: *Tree, root: usize, key: i64) usize {
        if (root == 0) { self.used += 1; const node = self.used; self.key[node] = key; self.height[node] = 1; self.size[node] = 1; return node; }
        if (key < self.key[root]) {
            self.left[root] = self.insert(self.left[root], key);
        } else if (key > self.key[root]) {
            self.right[root] = self.insert(self.right[root], key);
        } else return root;
        return self.rebalance(root);
    }
    fn minimumNode(self: *const Tree, root_start: usize) usize {
        var root = root_start;
        while (self.left[root] != 0) root = self.left[root];
        return root;
    }
    fn erase(self: *Tree, root: usize, key: i64) usize {
        if (root == 0) return 0;
        if (key < self.key[root]) {
            self.left[root] = self.erase(self.left[root], key);
        } else if (key > self.key[root]) {
            self.right[root] = self.erase(self.right[root], key);
        } else if (self.left[root] == 0) {
            return self.right[root];
        } else if (self.right[root] == 0) {
            return self.left[root];
        }
        else {
            const next = self.minimumNode(self.right[root]);
            self.key[root] = self.key[next];
            self.right[root] = self.erase(self.right[root], self.key[next]);
        }
        return self.rebalance(root);
    }
    fn kth(self: *const Tree, root_start: usize, rank_input: i64) i64 {
        if (rank_input < 1 or rank_input > self.nodeSize(root_start)) return -1;
        var root = root_start; var rank = rank_input;
        while (root != 0) {
            const left_count = self.nodeSize(self.left[root]);
            if (rank == left_count + 1) return self.key[root];
            if (rank <= left_count) root = self.left[root] else { rank -= left_count + 1; root = self.right[root]; }
        }
        return -1;
    }
    fn countLe(self: *const Tree, root_start: usize, key: i64) i64 {
        var root = root_start; var count: i64 = 0;
        while (root != 0) { if (self.key[root] <= key) { count += self.nodeSize(self.left[root]) + 1; root = self.right[root]; } else root = self.left[root]; }
        return count;
    }
    fn predecessor(self: *const Tree, root_start: usize, key: i64) i64 {
        var root = root_start; var answer: i64 = -1;
        while (root != 0) { if (self.key[root] <= key) { answer = self.key[root]; root = self.right[root]; } else root = self.left[root]; }
        return answer;
    }
    fn successor(self: *const Tree, root_start: usize, key: i64) i64 {
        var root = root_start; var answer: i64 = -1;
        while (root != 0) { if (self.key[root] >= key) { answer = self.key[root]; root = self.left[root]; } else root = self.right[root]; }
        return answer;
    }
};

export fn ordered_set_avl_order_statistics(input: ?[*]const i64, length: usize) i64 {
    if (input == null or length < 2 or length > 99) return -1;
    const values = input.?[0..length];
    const n = values[0]; const q = values[1];
    if (n < 0 or n > MAX_ITEMS or q < 0 or q > MAX_OPS or length != @as(usize, @intCast(2 + n + 2 * q))) return -1;
    for (0..@intCast(n)) |i| { const key = values[2 + i]; if (key < 0 or key > MAX_KEY or (i > 0 and values[1 + i] >= key)) return -1; }
    for (0..@intCast(q)) |i| { const op = values[2 + @as(usize, @intCast(n)) + 2 * i]; const key = values[3 + @as(usize, @intCast(n)) + 2 * i]; if (op < 0 or op > 5 or key < 0 or key > MAX_KEY or (op == 2 and key < 1)) return -1; }
    var tree = Tree{};
    var root: usize = 0;
    for (0..@intCast(n)) |i| root = tree.insert(root, values[2 + i]);
    var checksum: i64 = 0; var query_index: i64 = 0;
    for (0..@intCast(q)) |i| {
        const op = values[2 + @as(usize, @intCast(n)) + 2 * i]; const key = values[3 + @as(usize, @intCast(n)) + 2 * i];
        if (op == 0) root = tree.insert(root, key)
        else if (op == 1) root = tree.erase(root, key)
        else { const answer = if (op == 2) tree.kth(root, key) else if (op == 3) tree.countLe(root, key) else if (op == 4) tree.predecessor(root, key) else tree.successor(root, key); query_index += 1; checksum += query_index * (answer + 1); }
    }
    return checksum;
}
