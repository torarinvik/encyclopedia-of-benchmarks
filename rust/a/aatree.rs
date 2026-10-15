const MAX_OPERATIONS: usize = 256;

#[derive(Clone, Copy)]
struct Node {
    key: i32,
    left: i32,
    right: i32,
    level: i32,
}
impl Node {
    const EMPTY: Self = Self { key: 0, left: -1, right: -1, level: 0 };
}
struct AaTree {
    nodes: [Node; MAX_OPERATIONS],
    used: usize,
}
impl AaTree {
    fn new() -> Self { Self { nodes: [Node::EMPTY; MAX_OPERATIONS], used: 0 } }
    fn level(&self, node: i32) -> i32 { if node < 0 { 0 } else { self.nodes[node as usize].level } }
    fn contains(&self, mut root: i32, key: i32) -> bool {
        while root >= 0 {
            let node = &self.nodes[root as usize];
            if key < node.key { root = node.left; }
            else if key > node.key { root = node.right; }
            else { return true; }
        }
        false
    }
    fn skew(&mut self, root: i32) -> i32 {
        if root < 0 { return root; }
        let left = self.nodes[root as usize].left;
        if left < 0 || self.nodes[left as usize].level != self.nodes[root as usize].level { return root; }
        self.nodes[root as usize].left = self.nodes[left as usize].right;
        self.nodes[left as usize].right = root;
        left
    }
    fn split(&mut self, root: i32) -> i32 {
        if root < 0 { return root; }
        let right = self.nodes[root as usize].right;
        if right < 0 { return root; }
        let right_right = self.nodes[right as usize].right;
        if right_right < 0 || self.nodes[root as usize].level != self.nodes[right_right as usize].level { return root; }
        self.nodes[root as usize].right = self.nodes[right as usize].left;
        self.nodes[right as usize].left = root;
        self.nodes[right as usize].level += 1;
        right
    }
    fn insert_node(&mut self, root: i32, key: i32) -> i32 {
        if root < 0 {
            let fresh = self.used as i32;
            self.used += 1;
            self.nodes[fresh as usize] = Node { key, left: -1, right: -1, level: 1 };
            return fresh;
        }
        let index = root as usize;
        if key < self.nodes[index].key {
            let child = self.nodes[index].left;
            self.nodes[index].left = self.insert_node(child, key);
        } else {
            let child = self.nodes[index].right;
            self.nodes[index].right = self.insert_node(child, key);
        }
        let root = self.skew(root);
        self.split(root)
    }
    fn minimum_node(&self, mut root: i32) -> i32 {
        while self.nodes[root as usize].left >= 0 { root = self.nodes[root as usize].left; }
        root
    }
    fn maximum_node(&self, mut root: i32) -> i32 {
        while self.nodes[root as usize].right >= 0 { root = self.nodes[root as usize].right; }
        root
    }
    fn decrease_level(&mut self, root: i32) -> i32 {
        let index = root as usize;
        let new_level = self.level(self.nodes[index].left).min(self.level(self.nodes[index].right)) + 1;
        if new_level < self.nodes[index].level {
            self.nodes[index].level = new_level;
            let right = self.nodes[index].right;
            if right >= 0 && new_level < self.nodes[right as usize].level { self.nodes[right as usize].level = new_level; }
        }
        root
    }
    fn remove_node(&mut self, root: i32, key: i32) -> i32 {
        let index = root as usize;
        if key < self.nodes[index].key {
            let child = self.nodes[index].left;
            self.nodes[index].left = self.remove_node(child, key);
        } else if key > self.nodes[index].key {
            let child = self.nodes[index].right;
            self.nodes[index].right = self.remove_node(child, key);
        } else if self.nodes[index].left < 0 && self.nodes[index].right < 0 {
            return -1;
        } else if self.nodes[index].left < 0 {
            let successor = self.minimum_node(self.nodes[index].right);
            let successor_key = self.nodes[successor as usize].key;
            self.nodes[index].key = successor_key;
            let child = self.nodes[index].right;
            self.nodes[index].right = self.remove_node(child, successor_key);
        } else {
            let predecessor = self.maximum_node(self.nodes[index].left);
            let predecessor_key = self.nodes[predecessor as usize].key;
            self.nodes[index].key = predecessor_key;
            let child = self.nodes[index].left;
            self.nodes[index].left = self.remove_node(child, predecessor_key);
        }
        let root = self.decrease_level(root);
        let root = self.skew(root);
        let right = self.nodes[root as usize].right;
        if right >= 0 {
            let right = self.skew(right);
            let right_right = self.nodes[right as usize].right;
            if right_right >= 0 { self.nodes[right as usize].right = self.skew(right_right); }
            self.nodes[root as usize].right = right;
        }
        let root = self.split(root);
        let right = self.nodes[root as usize].right;
        if right >= 0 { self.nodes[root as usize].right = self.split(right); }
        root
    }
}

fn write_i32(output: &mut [u8], offset: usize, value: i32) {
    output[offset..offset + 4].copy_from_slice(&value.to_le_bytes());
}

#[no_mangle]
pub unsafe extern "C" fn aatree(input: *const i64, length: usize, output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 1 { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    if values[0] < 0 || values[0] > MAX_OPERATIONS as i64 { return -1; }
    let operation_count = values[0] as usize;
    if length != 1 + 2 * operation_count { return -1; }
    let output_bytes = 4 * operation_count;
    if output_bytes > 0 && (output.is_null() || capacity < output_bytes) { return -2; }
    let output_slice = if output_bytes == 0 { &mut [] } else { std::slice::from_raw_parts_mut(output, output_bytes) };
    let mut tree = AaTree::new();
    let mut root = -1;
    let mut size = 0i32;
    for operation in 0..operation_count {
        let opcode = values[1 + 2 * operation];
        let raw_key = values[2 + 2 * operation];
        if !(0..=4).contains(&opcode) { return -1; }
        if opcode <= 2 && (raw_key < i32::MIN as i64 || raw_key > i32::MAX as i64) { return -1; }
        if opcode >= 3 && raw_key != 0 { return -1; }
        let key = raw_key as i32;
        let result = match opcode {
            0 => {
                if tree.contains(root, key) { return -1; }
                root = tree.insert_node(root, key);
                size += 1;
                size
            }
            1 => {
                if !tree.contains(root, key) { return -1; }
                root = tree.remove_node(root, key);
                size -= 1;
                size
            }
            2 => i32::from(tree.contains(root, key)),
            3 if root >= 0 => tree.nodes[tree.minimum_node(root) as usize].key,
            4 if root >= 0 => tree.nodes[tree.maximum_node(root) as usize].key,
            _ => return -1,
        };
        write_i32(output_slice, 4 * operation, result);
    }
    output_bytes as i64
}
