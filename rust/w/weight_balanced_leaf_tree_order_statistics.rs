const MAX_OPERATIONS: i64 = 64;
const MISSING: i64 = -129;
const NODE_CAPACITY: usize = 129;

struct Tree {
    left: [usize; NODE_CAPACITY],
    right: [usize; NODE_CAPACITY],
    size: [usize; NODE_CAPACITY],
    free_next: [usize; NODE_CAPACITY],
    key: [i64; NODE_CAPACITY],
    maximum: [i64; NODE_CAPACITY],
    next_node: usize,
    free_head: usize,
}

impl Tree {
    fn new() -> Self {
        Self { left: [0; NODE_CAPACITY], right: [0; NODE_CAPACITY], size: [0; NODE_CAPACITY],
            free_next: [0; NODE_CAPACITY], key: [0; NODE_CAPACITY], maximum: [0; NODE_CAPACITY],
            next_node: 1, free_head: 0 }
    }
    fn allocate(&mut self) -> usize {
        let node;
        if self.free_head != 0 {
            node = self.free_head;
            self.free_head = self.free_next[node];
        } else {
            node = self.next_node;
            self.next_node += 1;
        }
        self.left[node] = 0; self.right[node] = 0; self.size[node] = 0;
        self.free_next[node] = 0; self.key[node] = 0; self.maximum[node] = 0;
        node
    }
    fn release(&mut self, node: usize) {
        self.left[node] = 0; self.right[node] = 0; self.size[node] = 0;
        self.key[node] = 0; self.maximum[node] = 0;
        self.free_next[node] = self.free_head;
        self.free_head = node;
    }
    fn leaf(&mut self, value: i64) -> usize {
        let node = self.allocate();
        self.key[node] = value; self.maximum[node] = value; self.size[node] = 1;
        node
    }
    fn join(&mut self, a: usize, b: usize) -> usize {
        let node = self.allocate();
        self.left[node] = a; self.right[node] = b;
        self.size[node] = self.size[a] + self.size[b];
        self.maximum[node] = self.maximum[b];
        node
    }
    fn cut(&mut self, node: usize) -> (usize, usize) {
        let pair = (self.left[node], self.right[node]);
        self.release(node);
        pair
    }
    fn too_heavy(a: usize, b: usize) -> bool { a > 3 * b }
    fn merge(&mut self, a: usize, b: usize) -> usize {
        if a == 0 { return b; }
        if b == 0 { return a; }
        if Self::too_heavy(self.size[a], self.size[b]) {
            let (x, y) = self.cut(a);
            let merged = self.merge(y, b);
            let node = self.join(x, merged);
            return self.rebalance(node);
        }
        if Self::too_heavy(self.size[b], self.size[a]) {
            let (x, y) = self.cut(b);
            let merged = self.merge(a, x);
            let node = self.join(merged, y);
            return self.rebalance(node);
        }
        self.join(a, b)
    }
    fn rebalance(&mut self, node: usize) -> usize {
        if self.size[node] == 1 { return node; }
        let (a, b) = (self.left[node], self.right[node]);
        if Self::too_heavy(self.size[a], self.size[b]) || Self::too_heavy(self.size[b], self.size[a]) {
            let (x, y) = self.cut(node);
            return self.merge(x, y);
        }
        node
    }
    fn insert(&mut self, node: usize, value: i64) -> usize {
        if node == 0 { return self.leaf(value); }
        if self.size[node] == 1 {
            if value <= self.key[node] {
                let added = self.leaf(value);
                return self.join(added, node);
            }
            let added = self.leaf(value);
            return self.join(node, added);
        }
        let a = self.left[node];
        if value <= self.maximum[a] {
            let child = self.insert(a, value);
            self.left[node] = child;
        } else {
            let b = self.right[node];
            let child = self.insert(b, value);
            self.right[node] = child;
        }
        let a = self.left[node]; let b = self.right[node];
        self.size[node] = self.size[a] + self.size[b];
        self.maximum[node] = self.maximum[b];
        self.rebalance(node)
    }
    fn remove(&mut self, node: usize, value: i64) -> (usize, bool) {
        if node == 0 { return (0, false); }
        if self.size[node] == 1 {
            if self.key[node] != value { return (node, false); }
            self.release(node);
            return (0, true);
        }
        let a = self.left[node];
        let (new_child, removed);
        if value <= self.maximum[a] {
            (new_child, removed) = self.remove(a, value);
            self.left[node] = new_child;
        } else {
            let b = self.right[node];
            (new_child, removed) = self.remove(b, value);
            self.right[node] = new_child;
        }
        if !removed { return (node, false); }
        let (a, b) = (self.left[node], self.right[node]);
        if a == 0 || b == 0 {
            let child = if a != 0 { a } else { b };
            self.release(node);
            return (child, true);
        }
        self.size[node] = self.size[a] + self.size[b];
        self.maximum[node] = self.maximum[b];
        (self.rebalance(node), true)
    }
    fn rank(&self, node: usize, value: i64) -> i64 {
        if node == 0 { return 0; }
        if self.size[node] == 1 { return if self.key[node] < value { 1 } else { 0 }; }
        let a = self.left[node];
        if value <= self.maximum[a] { self.rank(a, value) }
        else { self.size[a] as i64 + self.rank(self.right[node], value) }
    }
    fn kth(&self, mut node: usize, mut index: i64) -> i64 {
        if node == 0 || index >= self.size[node] as i64 { return MISSING; }
        while self.size[node] != 1 {
            let a = self.left[node];
            if index < self.size[a] as i64 { node = a; }
            else { index -= self.size[a] as i64; node = self.right[node]; }
        }
        self.key[node]
    }
    fn predecessor(&self, node: usize, value: i64) -> i64 {
        if node == 0 { return MISSING; }
        if self.size[node] == 1 { return if self.key[node] < value { self.key[node] } else { MISSING }; }
        let a = self.left[node];
        if value <= self.maximum[a] { return self.predecessor(a, value); }
        let answer = self.predecessor(self.right[node], value);
        if answer == MISSING { self.maximum[a] } else { answer }
    }
    fn successor(&self, node: usize, value: i64) -> i64 {
        if node == 0 { return MISSING; }
        if self.size[node] == 1 { return if self.key[node] > value { self.key[node] } else { MISSING }; }
        let a = self.left[node];
        if value < self.maximum[a] { self.successor(a, value) }
        else { self.successor(self.right[node], value) }
    }
}

#[no_mangle]
pub unsafe extern "C" fn weight_balanced_leaf_tree_order_statistics(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 1 || length > 130 { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let q = values[0];
    if q < 0 || q > MAX_OPERATIONS || length != (1 + 2 * q) as usize { return -1; }
    for i in 0..q as usize {
        let op = values[1 + 2 * i]; let arg = values[2 + 2 * i];
        if !(0..=5).contains(&op) { return -1; }
        if op == 3 { if !(0..MAX_OPERATIONS).contains(&arg) { return -1; } }
        else if !(-128..=127).contains(&arg) { return -1; }
    }
    let mut tree = Tree::new();
    let mut root = 0usize;
    let mut checksum = 0i64;
    for i in 0..q as usize {
        let op = values[1 + 2 * i]; let arg = values[2 + 2 * i];
        if op == 0 { root = tree.insert(root, arg); }
        else if op == 1 { root = tree.remove(root, arg).0; }
        else {
            let answer = match op {
                2 => tree.rank(root, arg),
                3 => tree.kth(root, arg),
                4 => tree.predecessor(root, arg),
                _ => tree.successor(root, arg),
            };
            checksum += (i as i64 + 1) * (answer - MISSING);
        }
    }
    checksum
}
