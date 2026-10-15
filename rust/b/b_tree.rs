/// Fixed-capacity B-tree multiset with split-on-descent insertion.
const MAX_NODE_COUNT: usize = 257;
const MAX_NODE_KEYS: usize = 15;
const MAX_NODE_CHILDREN: usize = 16;
const MAX_KEY_COUNT: usize = 256;
const MAX_OPERATIONS: i64 = 511;
const OFFSET: i64 = 1_000_000;
const HASH_MOD: i64 = 1_000_000_007;

struct BTree {
    keys: [[i64; MAX_NODE_KEYS]; MAX_NODE_COUNT],
    children: [[usize; MAX_NODE_CHILDREN]; MAX_NODE_COUNT],
    key_count: [usize; MAX_NODE_COUNT],
    leaf: [bool; MAX_NODE_COUNT],
    used_nodes: usize,
    root: usize,
    min_degree: usize,
}

impl BTree {
    fn new(min_degree: usize) -> Self {
        let mut tree = Self {
            keys: [[0; MAX_NODE_KEYS]; MAX_NODE_COUNT],
            children: [[0; MAX_NODE_CHILDREN]; MAX_NODE_COUNT],
            key_count: [0; MAX_NODE_COUNT],
            leaf: [false; MAX_NODE_COUNT],
            used_nodes: 1,
            root: 0,
            min_degree,
        };
        tree.leaf[0] = true;
        tree
    }

    fn split_child(&mut self, parent: usize, child_index: usize) -> bool {
        if self.used_nodes >= MAX_NODE_COUNT { return false; }
        let child = self.children[parent][child_index];
        let degree = self.min_degree;
        let sibling = self.used_nodes;
        self.used_nodes += 1;
        self.leaf[sibling] = self.leaf[child];
        self.key_count[sibling] = degree - 1;
        for i in 0..degree - 1 { self.keys[sibling][i] = self.keys[child][degree + i]; }
        if !self.leaf[child] {
            for i in 0..degree { self.children[sibling][i] = self.children[child][degree + i]; }
        }
        let parent_count = self.key_count[parent];
        for i in (child_index + 1..=parent_count + 1).rev() { self.children[parent][i] = self.children[parent][i - 1]; }
        self.children[parent][child_index + 1] = sibling;
        for i in (child_index..parent_count).rev() { self.keys[parent][i + 1] = self.keys[parent][i]; }
        self.keys[parent][child_index] = self.keys[child][degree - 1];
        self.key_count[child] = degree - 1;
        self.key_count[parent] = parent_count + 1;
        true
    }

    fn insert_non_full(&mut self, node: usize, key: i64) -> bool {
        let mut index = self.key_count[node];
        if self.leaf[node] {
            while index > 0 && key <= self.keys[node][index - 1] {
                self.keys[node][index] = self.keys[node][index - 1];
                index -= 1;
            }
            self.keys[node][index] = key;
            self.key_count[node] += 1;
            return true;
        }
        while index > 0 && key <= self.keys[node][index - 1] { index -= 1; }
        let child = self.children[node][index];
        if self.key_count[child] == 2 * self.min_degree - 1 {
            if !self.split_child(node, index) { return false; }
            if self.keys[node][index] < key { index += 1; }
        }
        self.insert_non_full(self.children[node][index], key)
    }

    fn insert(&mut self, key: i64) -> bool {
        if self.key_count[self.root] == 2 * self.min_degree - 1 {
            if self.used_nodes + 2 > MAX_NODE_COUNT { return false; }
            let old_root = self.root;
            let new_root = self.used_nodes;
            self.used_nodes += 1;
            self.leaf[new_root] = false;
            self.children[new_root][0] = old_root;
            self.root = new_root;
            if !self.split_child(new_root, 0) { return false; }
        }
        self.insert_non_full(self.root, key)
    }

    fn search(&self, key: i64) -> bool {
        let mut node = self.root;
        loop {
            let mut index = 0;
            while index < self.key_count[node] && key > self.keys[node][index] { index += 1; }
            if index < self.key_count[node] && key == self.keys[node][index] { return true; }
            if self.leaf[node] { return false; }
            node = self.children[node][index];
        }
    }

    fn walk(&self, operation_count: usize, add_ordered_sum: bool) -> (i64, i64) {
        let mut node_stack = [0usize; 32];
        let mut position_stack = [0usize; 32];
        let mut depth = 1usize;
        let mut index = 0usize;
        let mut hash = 0i64;
        let mut ordered_sum = 0i64;
        node_stack[0] = self.root;
        while depth > 0 {
            let top = depth - 1;
            let node = node_stack[top];
            let count = self.key_count[node];
            if self.leaf[node] {
                if position_stack[top] == count { depth -= 1; continue; }
                let value = self.keys[node][position_stack[top]];
                position_stack[top] += 1;
                hash = (hash * 257 + value + 1_000_001) % HASH_MOD;
                if add_ordered_sum { ordered_sum += (operation_count as i64 + index as i64 + 1) * (value + OFFSET); }
                index += 1;
            } else if position_stack[top] > 2 * count {
                depth -= 1;
            } else {
                let position = position_stack[top];
                position_stack[top] += 1;
                if position % 2 == 0 {
                    node_stack[depth] = self.children[node][position / 2];
                    position_stack[depth] = 0;
                    depth += 1;
                } else {
                    let value = self.keys[node][position / 2];
                    hash = (hash * 257 + value + 1_000_001) % HASH_MOD;
                    if add_ordered_sum { ordered_sum += (operation_count as i64 + index as i64 + 1) * (value + OFFSET); }
                    index += 1;
                }
            }
        }
        (hash, ordered_sum)
    }
}

#[no_mangle]
pub unsafe extern "C" fn b_tree_benchmark(values: *const i64, length: usize) -> i64 {
    if values.is_null() || length < 2 || length > 1024 { return -1; }
    let branch_factor = *values;
    let operation_count_value = *values.add(1);
    if !(2..=8).contains(&branch_factor) || !(0..=MAX_OPERATIONS).contains(&operation_count_value) { return -1; }
    let operation_count = operation_count_value as usize;
    if length != 2 + 2 * operation_count { return -1; }
    let mut tree = BTree::new(branch_factor as usize);
    let mut key_count = 0usize;
    let mut checksum = 0i64;
    for operation in 0..operation_count {
        let opcode = *values.add(2 + 2 * operation);
        let payload = *values.add(3 + 2 * operation);
        let observed = if opcode == 0 {
            if !(-OFFSET..=OFFSET).contains(&payload) || key_count == MAX_KEY_COUNT || !tree.insert(payload) { return -1; }
            key_count += 1;
            1
        } else if opcode == 1 {
            if !(-OFFSET..=OFFSET).contains(&payload) { return -1; }
            i64::from(tree.search(payload))
        } else if opcode == 2 {
            if payload != 0 { return -1; }
            tree.walk(0, false).0
        } else { return -1; };
        checksum += (operation as i64 + 1) * (observed + OFFSET);
    }
    checksum + tree.walk(operation_count, true).1
}
