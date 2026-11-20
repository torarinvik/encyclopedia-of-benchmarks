const MAX_OPS: i64 = 128;
const MISSING: i64 = -1025;

struct SizeBalancedTree {
    key: [i64; 129],
    size: [usize; 129],
    left: [usize; 129],
    right: [usize; 129],
    used: usize,
}

impl SizeBalancedTree {
    fn new() -> Self {
        Self { key: [0; 129], size: [0; 129], left: [0; 129], right: [0; 129], used: 0 }
    }
    fn subtree_size(&self, node: usize) -> usize { if node == 0 { 0 } else { self.size[node] } }
    fn refresh(&mut self, node: usize) {
        self.size[node] = self.subtree_size(self.left[node]) + self.subtree_size(self.right[node]) + 1;
    }
    fn rotate_right(&mut self, root: usize) -> usize {
        let pivot = self.left[root];
        self.left[root] = self.right[pivot];
        self.right[pivot] = root;
        self.refresh(root);
        self.refresh(pivot);
        pivot
    }
    fn rotate_left(&mut self, root: usize) -> usize {
        let pivot = self.right[root];
        self.right[root] = self.left[pivot];
        self.left[pivot] = root;
        self.refresh(root);
        self.refresh(pivot);
        pivot
    }
    fn maintain(&mut self, root_input: usize, right_side: bool) -> usize {
        if root_input == 0 { return 0; }
        let mut root = root_input;
        if !right_side {
            if self.subtree_size(self.left[self.left[root]]) > self.subtree_size(self.right[root]) {
                root = self.rotate_right(root);
            } else if self.subtree_size(self.right[self.left[root]]) > self.subtree_size(self.right[root]) {
                let child = self.left[root];
                self.left[root] = self.rotate_left(child);
                root = self.rotate_right(root);
            } else { return root; }
        } else if self.subtree_size(self.right[self.right[root]]) > self.subtree_size(self.left[root]) {
            root = self.rotate_left(root);
        } else if self.subtree_size(self.left[self.right[root]]) > self.subtree_size(self.left[root]) {
            let child = self.right[root];
            self.right[root] = self.rotate_right(child);
            root = self.rotate_left(root);
        } else { return root; }
        let left = self.left[root];
        self.left[root] = self.maintain(left, false);
        let right = self.right[root];
        self.right[root] = self.maintain(right, true);
        root = self.maintain(root, false);
        root = self.maintain(root, true);
        root
    }
    fn insert(&mut self, root_input: usize, key: i64) -> usize {
        if root_input == 0 {
            self.used += 1;
            let node = self.used;
            self.key[node] = key;
            self.size[node] = 1;
            return node;
        }
        let mut root = root_input;
        if key < self.key[root] {
            let child = self.left[root];
            self.left[root] = self.insert(child, key);
            self.refresh(root);
            root = self.maintain(root, false);
        } else if key > self.key[root] {
            let child = self.right[root];
            self.right[root] = self.insert(child, key);
            self.refresh(root);
            root = self.maintain(root, true);
        }
        root
    }
    fn rank(&self, mut root: usize, key: i64) -> i64 {
        let mut answer = 0i64;
        while root != 0 {
            if key <= self.key[root] { root = self.left[root]; }
            else { answer += self.subtree_size(self.left[root]) as i64 + 1; root = self.right[root]; }
        }
        answer
    }
    fn kth(&self, mut root: usize, mut index: i64) -> i64 {
        while root != 0 {
            let left_count = self.subtree_size(self.left[root]) as i64;
            if index < left_count { root = self.left[root]; }
            else if index == left_count { return self.key[root]; }
            else { index -= left_count + 1; root = self.right[root]; }
        }
        MISSING
    }
    fn predecessor(&self, mut root: usize, key: i64) -> i64 {
        let mut answer = MISSING;
        while root != 0 {
            if self.key[root] < key { answer = self.key[root]; root = self.right[root]; }
            else { root = self.left[root]; }
        }
        answer
    }
    fn successor(&self, mut root: usize, key: i64) -> i64 {
        let mut answer = MISSING;
        while root != 0 {
            if self.key[root] > key { answer = self.key[root]; root = self.left[root]; }
            else { root = self.right[root]; }
        }
        answer
    }
}

#[no_mangle]
pub unsafe extern "C" fn size_balanced_ordered_set(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 1 || length > 257 { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let q = values[0];
    if q < 0 || q > MAX_OPS || length != (1 + 2 * q) as usize { return -1; }
    for i in 0..q as usize {
        let op = values[1 + 2 * i];
        let arg = values[2 + 2 * i];
        if !(0..=4).contains(&op) { return -1; }
        if op == 2 {
            if !(0..=127).contains(&arg) { return -1; }
        } else if !(-1024..=1023).contains(&arg) { return -1; }
    }

    let mut tree = SizeBalancedTree::new();
    let mut root = 0usize;
    let mut checksum = 0i64;
    for i in 0..q as usize {
        let op = values[1 + 2 * i];
        let arg = values[2 + 2 * i];
        if op == 0 { root = tree.insert(root, arg); }
        else {
            let answer = match op {
                1 => tree.rank(root, arg),
                2 => tree.kth(root, arg),
                3 => tree.predecessor(root, arg),
                _ => tree.successor(root, arg),
            };
            checksum += (i as i64 + 1) * (answer - MISSING);
        }
    }
    checksum
}
