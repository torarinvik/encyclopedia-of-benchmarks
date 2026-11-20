const MAX_OPS: i64 = 128;
const MISSING: i64 = -1025;

const Tree = struct {
    key: [129]i64 = [_]i64{0} ** 129,
    size: [129]usize = [_]usize{0} ** 129,
    left: [129]usize = [_]usize{0} ** 129,
    right: [129]usize = [_]usize{0} ** 129,
    used: usize = 0,

    fn subtreeSize(self: *const Tree, node: usize) usize { return if (node == 0) 0 else self.size[node]; }
    fn refresh(self: *Tree, node: usize) void {
        self.size[node] = self.subtreeSize(self.left[node]) + self.subtreeSize(self.right[node]) + 1;
    }
    fn rotateRight(self: *Tree, root: usize) usize {
        const pivot = self.left[root];
        self.left[root] = self.right[pivot];
        self.right[pivot] = root;
        self.refresh(root);
        self.refresh(pivot);
        return pivot;
    }
    fn rotateLeft(self: *Tree, root: usize) usize {
        const pivot = self.right[root];
        self.right[root] = self.left[pivot];
        self.left[pivot] = root;
        self.refresh(root);
        self.refresh(pivot);
        return pivot;
    }
    fn maintain(self: *Tree, root_input: usize, right_side: bool) usize {
        if (root_input == 0) return 0;
        var root = root_input;
        if (!right_side) {
            if (self.subtreeSize(self.left[self.left[root]]) > self.subtreeSize(self.right[root])) {
                root = self.rotateRight(root);
            } else if (self.subtreeSize(self.right[self.left[root]]) > self.subtreeSize(self.right[root])) {
                const child = self.left[root];
                self.left[root] = self.rotateLeft(child);
                root = self.rotateRight(root);
            } else return root;
        } else if (self.subtreeSize(self.right[self.right[root]]) > self.subtreeSize(self.left[root])) {
            root = self.rotateLeft(root);
        } else if (self.subtreeSize(self.left[self.right[root]]) > self.subtreeSize(self.left[root])) {
            const child = self.right[root];
            self.right[root] = self.rotateRight(child);
            root = self.rotateLeft(root);
        } else return root;
        const left = self.left[root];
        self.left[root] = self.maintain(left, false);
        const right = self.right[root];
        self.right[root] = self.maintain(right, true);
        root = self.maintain(root, false);
        root = self.maintain(root, true);
        return root;
    }
    fn insert(self: *Tree, root_input: usize, key: i64) usize {
        if (root_input == 0) {
            self.used += 1;
            const node = self.used;
            self.key[node] = key;
            self.size[node] = 1;
            return node;
        }
        var root = root_input;
        if (key < self.key[root]) {
            const child = self.left[root];
            self.left[root] = self.insert(child, key);
            self.refresh(root);
            root = self.maintain(root, false);
        } else if (key > self.key[root]) {
            const child = self.right[root];
            self.right[root] = self.insert(child, key);
            self.refresh(root);
            root = self.maintain(root, true);
        }
        return root;
    }
    fn rank(self: *const Tree, root_input: usize, key: i64) i64 {
        var root = root_input;
        var answer: i64 = 0;
        while (root != 0) {
            if (key <= self.key[root]) root = self.left[root] else {
                answer += @intCast(self.subtreeSize(self.left[root]) + 1);
                root = self.right[root];
            }
        }
        return answer;
    }
    fn kth(self: *const Tree, root_input: usize, index_input: i64) i64 {
        var root = root_input;
        var index = index_input;
        while (root != 0) {
            const left_count: i64 = @intCast(self.subtreeSize(self.left[root]));
            if (index < left_count) root = self.left[root] else if (index == left_count) return self.key[root] else {
                index -= left_count + 1;
                root = self.right[root];
            }
        }
        return MISSING;
    }
    fn predecessor(self: *const Tree, root_input: usize, key: i64) i64 {
        var root = root_input;
        var answer = MISSING;
        while (root != 0) {
            if (self.key[root] < key) { answer = self.key[root]; root = self.right[root]; } else root = self.left[root];
        }
        return answer;
    }
    fn successor(self: *const Tree, root_input: usize, key: i64) i64 {
        var root = root_input;
        var answer = MISSING;
        while (root != 0) {
            if (self.key[root] > key) { answer = self.key[root]; root = self.left[root]; } else root = self.right[root];
        }
        return answer;
    }
};

export fn size_balanced_ordered_set(input: ?[*]const i64, length: usize) i64 {
    if (input == null or length < 1 or length > 257) return -1;
    const values = input.?[0..length];
    const q = values[0];
    if (q < 0 or q > MAX_OPS or length != @as(usize, @intCast(1 + 2 * q))) return -1;
    for (0..@intCast(q)) |i| {
        const op = values[1 + 2 * i];
        const arg = values[2 + 2 * i];
        if (op < 0 or op > 4) return -1;
        if (op == 2) {
            if (arg < 0 or arg > 127) return -1;
        } else if (arg < -1024 or arg > 1023) return -1;
    }

    var tree = Tree{};
    var root: usize = 0;
    var checksum: i64 = 0;
    for (0..@intCast(q)) |i| {
        const op = values[1 + 2 * i];
        const arg = values[2 + 2 * i];
        if (op == 0) root = tree.insert(root, arg) else {
            const answer = if (op == 1) tree.rank(root, arg) else if (op == 2) tree.kth(root, arg) else if (op == 3) tree.predecessor(root, arg) else tree.successor(root, arg);
            checksum += (@as(i64, @intCast(i)) + 1) * (answer - MISSING);
        }
    }
    return checksum;
}
