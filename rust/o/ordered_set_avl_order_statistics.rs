const MAX_ITEMS: i64 = 32;
const MAX_OPS: i64 = 32;
const MAX_KEY: i64 = 1000;

struct Tree {
    key: [i64; 65],
    height: [i32; 65],
    size: [i32; 65],
    left: [usize; 65],
    right: [usize; 65],
    used: usize,
}

impl Tree {
    fn new() -> Self { Self { key: [0; 65], height: [0; 65], size: [0; 65], left: [0; 65], right: [0; 65], used: 0 } }
    fn h(&self, node: usize) -> i32 { if node == 0 { 0 } else { self.height[node] } }
    fn s(&self, node: usize) -> i32 { if node == 0 { 0 } else { self.size[node] } }
    fn refresh(&mut self, node: usize) {
        self.height[node] = self.h(self.left[node]).max(self.h(self.right[node])) + 1;
        self.size[node] = self.s(self.left[node]) + self.s(self.right[node]) + 1;
    }
    fn rotate_right(&mut self, root: usize) -> usize {
        let pivot = self.left[root]; self.left[root] = self.right[pivot]; self.right[pivot] = root;
        self.refresh(root); self.refresh(pivot); pivot
    }
    fn rotate_left(&mut self, root: usize) -> usize {
        let pivot = self.right[root]; self.right[root] = self.left[pivot]; self.left[pivot] = root;
        self.refresh(root); self.refresh(pivot); pivot
    }
    fn rebalance(&mut self, root: usize) -> usize {
        self.refresh(root);
        let difference = self.h(self.left[root]) - self.h(self.right[root]);
        if difference > 1 {
            let child = self.left[root];
            if self.h(self.left[child]) < self.h(self.right[child]) { self.left[root] = self.rotate_left(child); }
            return self.rotate_right(root);
        }
        if difference < -1 {
            let child = self.right[root];
            if self.h(self.right[child]) < self.h(self.left[child]) { self.right[root] = self.rotate_right(child); }
            return self.rotate_left(root);
        }
        root
    }
    fn insert(&mut self, root: usize, key: i64) -> usize {
        if root == 0 { self.used += 1; let node = self.used; self.key[node] = key; self.height[node] = 1; self.size[node] = 1; return node; }
        if key < self.key[root] { self.left[root] = self.insert(self.left[root], key); }
        else if key > self.key[root] { self.right[root] = self.insert(self.right[root], key); }
        else { return root; }
        self.rebalance(root)
    }
    fn min_node(&self, mut root: usize) -> usize { while self.left[root] != 0 { root = self.left[root]; } root }
    fn erase(&mut self, root: usize, key: i64) -> usize {
        if root == 0 { return 0; }
        if key < self.key[root] { self.left[root] = self.erase(self.left[root], key); }
        else if key > self.key[root] { self.right[root] = self.erase(self.right[root], key); }
        else if self.left[root] == 0 { return self.right[root]; }
        else if self.right[root] == 0 { return self.left[root]; }
        else { let next = self.min_node(self.right[root]); self.key[root] = self.key[next]; self.right[root] = self.erase(self.right[root], self.key[next]); }
        self.rebalance(root)
    }
    fn kth(&self, mut root: usize, mut rank: i64) -> i64 {
        if rank < 1 || rank > self.s(root) as i64 { return -1; }
        while root != 0 { let left_count = self.s(self.left[root]) as i64; if rank == left_count + 1 { return self.key[root]; } if rank <= left_count { root = self.left[root]; } else { rank -= left_count + 1; root = self.right[root]; } }
        -1
    }
    fn count_le(&self, mut root: usize, key: i64) -> i64 {
        let mut count = 0;
        while root != 0 { if self.key[root] <= key { count += self.s(self.left[root]) as i64 + 1; root = self.right[root]; } else { root = self.left[root]; } }
        count
    }
    fn predecessor(&self, mut root: usize, key: i64) -> i64 {
        let mut answer = -1;
        while root != 0 { if self.key[root] <= key { answer = self.key[root]; root = self.right[root]; } else { root = self.left[root]; } }
        answer
    }
    fn successor(&self, mut root: usize, key: i64) -> i64 {
        let mut answer = -1;
        while root != 0 { if self.key[root] >= key { answer = self.key[root]; root = self.left[root]; } else { root = self.right[root]; } }
        answer
    }
}

#[no_mangle]
pub unsafe extern "C" fn ordered_set_avl_order_statistics(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 2 || length > 99 { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let (n, q) = (values[0], values[1]);
    if n < 0 || n > MAX_ITEMS || q < 0 || q > MAX_OPS || length != (2 + n + 2 * q) as usize { return -1; }
    for i in 0..n as usize { let key = values[2 + i]; if !(0..=MAX_KEY).contains(&key) || (i > 0 && values[1 + i] >= key) { return -1; } }
    for i in 0..q as usize { let op = values[2 + n as usize + 2 * i]; let key = values[3 + n as usize + 2 * i]; if !(0..=5).contains(&op) || !(0..=MAX_KEY).contains(&key) || (op == 2 && key < 1) { return -1; } }
    let mut tree = Tree::new();
    let mut root = 0;
    for i in 0..n as usize { root = tree.insert(root, values[2 + i]); }
    let mut checksum = 0i64;
    let mut query_index = 0i64;
    for i in 0..q as usize {
        let op = values[2 + n as usize + 2 * i]; let key = values[3 + n as usize + 2 * i];
        if op == 0 { root = tree.insert(root, key); }
        else if op == 1 { root = tree.erase(root, key); }
        else {
            let answer = if op == 2 { tree.kth(root, key) } else if op == 3 { tree.count_le(root, key) } else if op == 4 { tree.predecessor(root, key) } else { tree.successor(root, key) };
            query_index += 1; checksum += query_index * (answer + 1);
        }
    }
    checksum
}
