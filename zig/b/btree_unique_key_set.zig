const MIN_DEGREE: usize = 255;
const MAX_NODE_KEYS: usize = 2 * MIN_DEGREE - 1;
const MAX_NODE_COUNT: usize = 32;
const MAX_INSERTS: usize = 2048;
const MAX_QUERIES: usize = 1024;
const MAX_DELETES: usize = 1024;
const MAX_OUTPUT_VALUES: usize = 2 + MAX_QUERIES + MAX_INSERTS;

const BTree = struct {
    keys: [MAX_NODE_COUNT][MAX_NODE_KEYS]i32 = @splat(@splat(0)),
    children: [MAX_NODE_COUNT][MAX_NODE_KEYS + 1]usize = @splat(@splat(0)),
    key_count: [MAX_NODE_COUNT]usize = @splat(0),
    leaf: [MAX_NODE_COUNT]bool = @splat(false),
    used_nodes: usize = 1,
    root: usize = 0,

    fn init() BTree {
        var tree = BTree{};
        tree.leaf[0] = true;
        return tree;
    }

    fn search(self: *const BTree, key: i32) bool {
        var node = self.root;
        while (true) {
            var index: usize = 0;
            while (index < self.key_count[node] and key > self.keys[node][index]) : (index += 1) {}
            if (index < self.key_count[node] and key == self.keys[node][index]) return true;
            if (self.leaf[node]) return false;
            node = self.children[node][index];
        }
    }

    fn splitChild(self: *BTree, parent: usize, index: usize) bool {
        if (self.used_nodes >= MAX_NODE_COUNT) return false;
        const child = self.children[parent][index];
        const sibling = self.used_nodes;
        self.used_nodes += 1;
        self.leaf[sibling] = self.leaf[child];
        for (0..MIN_DEGREE - 1) |i| self.keys[sibling][i] = self.keys[child][i + MIN_DEGREE];
        if (!self.leaf[child]) {
            for (0..MIN_DEGREE) |i| self.children[sibling][i] = self.children[child][i + MIN_DEGREE];
        }
        self.key_count[sibling] = MIN_DEGREE - 1;
        const parent_count = self.key_count[parent];
        var i = parent_count;
        while (i > index) : (i -= 1) self.keys[parent][i] = self.keys[parent][i - 1];
        i = parent_count + 1;
        while (i > index + 1) : (i -= 1) self.children[parent][i] = self.children[parent][i - 1];
        self.children[parent][index + 1] = sibling;
        self.keys[parent][index] = self.keys[child][MIN_DEGREE - 1];
        self.key_count[child] = MIN_DEGREE - 1;
        self.key_count[parent] = parent_count + 1;
        return true;
    }

    fn insertNonFull(self: *BTree, node: usize, key: i32) bool {
        var index = self.key_count[node];
        if (self.leaf[node]) {
            while (index > 0 and key < self.keys[node][index - 1]) : (index -= 1)
                self.keys[node][index] = self.keys[node][index - 1];
            self.keys[node][index] = key;
            self.key_count[node] += 1;
            return true;
        }
        while (index > 0 and key < self.keys[node][index - 1]) : (index -= 1) {}
        if (self.key_count[self.children[node][index]] == MAX_NODE_KEYS) {
            if (!self.splitChild(node, index)) return false;
            if (key > self.keys[node][index]) index += 1;
        }
        return self.insertNonFull(self.children[node][index], key);
    }

    fn insert(self: *BTree, key: i32) bool {
        if (self.key_count[self.root] == MAX_NODE_KEYS) {
            if (self.used_nodes >= MAX_NODE_COUNT) return false;
            const old_root = self.root;
            const new_root = self.used_nodes;
            self.used_nodes += 1;
            self.leaf[new_root] = false;
            self.children[new_root][0] = old_root;
            self.root = new_root;
            if (!self.splitChild(new_root, 0)) return false;
        }
        return self.insertNonFull(self.root, key);
    }

    fn predecessor(self: *const BTree, start: usize) i32 {
        var node = start;
        while (!self.leaf[node]) node = self.children[node][self.key_count[node]];
        return self.keys[node][self.key_count[node] - 1];
    }

    fn successor(self: *const BTree, start: usize) i32 {
        var node = start;
        while (!self.leaf[node]) node = self.children[node][0];
        return self.keys[node][0];
    }

    fn mergeChildren(self: *BTree, parent: usize, index: usize) void {
        const left = self.children[parent][index];
        const right = self.children[parent][index + 1];
        var left_count = self.key_count[left];
        self.keys[left][left_count] = self.keys[parent][index];
        left_count += 1;
        for (0..self.key_count[right]) |i| self.keys[left][left_count + i] = self.keys[right][i];
        if (!self.leaf[left]) {
            for (0..self.key_count[right] + 1) |i| self.children[left][left_count + i] = self.children[right][i];
        }
        self.key_count[left] = left_count + self.key_count[right];
        const parent_count = self.key_count[parent];
        for (index + 1..parent_count) |i| self.keys[parent][i - 1] = self.keys[parent][i];
        for (index + 2..parent_count + 1) |i| self.children[parent][i - 1] = self.children[parent][i];
        self.key_count[parent] -= 1;
    }

    fn borrowPrevious(self: *BTree, parent: usize, index: usize) void {
        const child = self.children[parent][index];
        const sibling = self.children[parent][index - 1];
        const count = self.key_count[child];
        var i = count;
        while (i > 0) : (i -= 1) self.keys[child][i] = self.keys[child][i - 1];
        if (!self.leaf[child]) {
            i = count + 1;
            while (i > 0) : (i -= 1) self.children[child][i] = self.children[child][i - 1];
        }
        self.keys[child][0] = self.keys[parent][index - 1];
        if (!self.leaf[child]) self.children[child][0] = self.children[sibling][self.key_count[sibling]];
        self.keys[parent][index - 1] = self.keys[sibling][self.key_count[sibling] - 1];
        self.key_count[child] += 1;
        self.key_count[sibling] -= 1;
    }

    fn borrowNext(self: *BTree, parent: usize, index: usize) void {
        const child = self.children[parent][index];
        const sibling = self.children[parent][index + 1];
        const child_count = self.key_count[child];
        const sibling_count = self.key_count[sibling];
        self.keys[child][child_count] = self.keys[parent][index];
        if (!self.leaf[child]) self.children[child][child_count + 1] = self.children[sibling][0];
        self.keys[parent][index] = self.keys[sibling][0];
        for (1..sibling_count) |i| self.keys[sibling][i - 1] = self.keys[sibling][i];
        if (!self.leaf[sibling]) {
            for (1..sibling_count + 1) |i| self.children[sibling][i - 1] = self.children[sibling][i];
        }
        self.key_count[child] += 1;
        self.key_count[sibling] -= 1;
    }

    fn fillChild(self: *BTree, parent: usize, index: usize) void {
        if (index > 0 and self.key_count[self.children[parent][index - 1]] >= MIN_DEGREE) {
            self.borrowPrevious(parent, index);
        } else if (index < self.key_count[parent] and self.key_count[self.children[parent][index + 1]] >= MIN_DEGREE) {
            self.borrowNext(parent, index);
        } else {
            self.mergeChildren(parent, if (index < self.key_count[parent]) index else index - 1);
        }
    }

    fn deleteFrom(self: *BTree, node: usize, key: i32) bool {
        var index: usize = 0;
        while (index < self.key_count[node] and self.keys[node][index] < key) : (index += 1) {}
        if (index < self.key_count[node] and self.keys[node][index] == key) {
            if (self.leaf[node]) {
                for (index + 1..self.key_count[node]) |i| self.keys[node][i - 1] = self.keys[node][i];
                self.key_count[node] -= 1;
            } else {
                const left = self.children[node][index];
                const right = self.children[node][index + 1];
                if (self.key_count[left] >= MIN_DEGREE) {
                    const replacement = self.predecessor(left);
                    self.keys[node][index] = replacement;
                    return self.deleteFrom(left, replacement);
                }
                if (self.key_count[right] >= MIN_DEGREE) {
                    const replacement = self.successor(right);
                    self.keys[node][index] = replacement;
                    return self.deleteFrom(right, replacement);
                }
                self.mergeChildren(node, index);
                return self.deleteFrom(left, key);
            }
            return true;
        }
        if (self.leaf[node]) return false;
        const was_last = index == self.key_count[node];
        if (self.key_count[self.children[node][index]] < MIN_DEGREE) self.fillChild(node, index);
        if (was_last and index > self.key_count[node]) index -= 1;
        return self.deleteFrom(self.children[node][index], key);
    }

    fn delete(self: *BTree, key: i32) bool {
        if (!self.deleteFrom(self.root, key)) return false;
        if (self.key_count[self.root] == 0 and !self.leaf[self.root]) self.root = self.children[self.root][0];
        return true;
    }

    fn traverse(self: *const BTree, node: usize, result: *[MAX_OUTPUT_VALUES]i64, length: *usize) void {
        for (0..self.key_count[node]) |i| {
            if (!self.leaf[node]) self.traverse(self.children[node][i], result, length);
            result[length.*] = self.keys[node][i];
            length.* += 1;
        }
        if (!self.leaf[node]) self.traverse(self.children[node][self.key_count[node]], result, length);
    }
};

fn storeI64Le(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @intCast((bits >> @intCast(byte * 8)) & 0xff);
}

export fn btree_unique_key_set(values: ?[*]const i64, length: usize, output: ?[*]u8, capacity: usize) i64 {
    if (values == null or length < 3 or length > 4096) return -1;
    const input = values.?[0..length];
    if (input[0] < 0 or input[0] > MAX_INSERTS) return -1;
    const insert_count: usize = @intCast(input[0]);
    const query_offset = 1 + insert_count;
    if (query_offset >= length or input[query_offset] < 0 or input[query_offset] > MAX_QUERIES) return -1;
    const query_count: usize = @intCast(input[query_offset]);
    const delete_count_offset = query_offset + 1 + query_count;
    if (delete_count_offset >= length or input[delete_count_offset] < 0 or input[delete_count_offset] > MAX_DELETES) return -1;
    const delete_count: usize = @intCast(input[delete_count_offset]);
    if (length != 3 + insert_count + query_count + delete_count) return -1;

    var tree = BTree.init();
    for (0..insert_count) |i| {
        const raw = input[1 + i];
        if (raw < -2147483648 or raw > 2147483647) return -1;
        const key: i32 = @intCast(raw);
        if (tree.search(key) or !tree.insert(key)) return -1;
    }
    var result: [MAX_OUTPUT_VALUES]i64 = @splat(0);
    var result_length: usize = 0;
    result[result_length] = @intCast(query_count);
    result_length += 1;
    const query_start = query_offset + 1;
    for (0..query_count) |i| {
        const raw = input[query_start + i];
        if (raw < -2147483648 or raw > 2147483647) return -1;
        result[result_length] = if (tree.search(@intCast(raw))) 1 else 0;
        result_length += 1;
    }
    const delete_start = delete_count_offset + 1;
    for (0..delete_count) |i| {
        const raw = input[delete_start + i];
        if (raw < -2147483648 or raw > 2147483647 or !tree.delete(@intCast(raw))) return -1;
    }
    const count_slot = result_length;
    result_length += 1;
    tree.traverse(tree.root, &result, &result_length);
    result[count_slot] = @intCast(result_length - count_slot - 1);
    const output_bytes = result_length * 8;
    if (output == null or capacity < output_bytes) return -2;
    const destination = output.?[0..output_bytes];
    for (0..result_length) |i| storeI64Le(destination.ptr, i * 8, result[i]);
    return @intCast(output_bytes);
}
