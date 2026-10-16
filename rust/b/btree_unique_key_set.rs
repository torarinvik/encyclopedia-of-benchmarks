const MIN_DEGREE: usize = 255;
const MAX_NODE_KEYS: usize = 2 * MIN_DEGREE - 1;
const MAX_NODE_COUNT: usize = 32;
const MAX_INSERTS: usize = 2048;
const MAX_QUERIES: usize = 1024;
const MAX_DELETES: usize = 1024;
const MAX_OUTPUT_VALUES: usize = 2 + MAX_QUERIES + MAX_INSERTS;

struct BTree {
    keys: [[i32; MAX_NODE_KEYS]; MAX_NODE_COUNT],
    children: [[usize; MAX_NODE_KEYS + 1]; MAX_NODE_COUNT],
    key_count: [usize; MAX_NODE_COUNT],
    leaf: [bool; MAX_NODE_COUNT],
    used_nodes: usize,
    root: usize,
}

impl BTree {
    fn new() -> Self {
        let mut tree = Self {
            keys: [[0; MAX_NODE_KEYS]; MAX_NODE_COUNT],
            children: [[0; MAX_NODE_KEYS + 1]; MAX_NODE_COUNT],
            key_count: [0; MAX_NODE_COUNT],
            leaf: [false; MAX_NODE_COUNT],
            used_nodes: 1,
            root: 0,
        };
        tree.leaf[0] = true;
        tree
    }

    fn search(&self, key: i32) -> bool {
        let mut node = self.root;
        loop {
            let mut index = 0;
            while index < self.key_count[node] && key > self.keys[node][index] { index += 1; }
            if index < self.key_count[node] && key == self.keys[node][index] { return true; }
            if self.leaf[node] { return false; }
            node = self.children[node][index];
        }
    }

    fn split_child(&mut self, parent: usize, index: usize) -> bool {
        if self.used_nodes >= MAX_NODE_COUNT { return false; }
        let child = self.children[parent][index];
        let sibling = self.used_nodes;
        self.used_nodes += 1;
        self.leaf[sibling] = self.leaf[child];
        for i in 0..MIN_DEGREE - 1 { self.keys[sibling][i] = self.keys[child][i + MIN_DEGREE]; }
        if !self.leaf[child] {
            for i in 0..MIN_DEGREE { self.children[sibling][i] = self.children[child][i + MIN_DEGREE]; }
        }
        self.key_count[sibling] = MIN_DEGREE - 1;
        let parent_count = self.key_count[parent];
        for i in (index + 1..=parent_count).rev() { self.children[parent][i + 1] = self.children[parent][i]; }
        self.children[parent][index + 1] = sibling;
        for i in (index..parent_count).rev() { self.keys[parent][i + 1] = self.keys[parent][i]; }
        self.keys[parent][index] = self.keys[child][MIN_DEGREE - 1];
        self.key_count[child] = MIN_DEGREE - 1;
        self.key_count[parent] = parent_count + 1;
        true
    }

    fn insert_non_full(&mut self, node: usize, key: i32) -> bool {
        let mut index = self.key_count[node];
        if self.leaf[node] {
            while index > 0 && key < self.keys[node][index - 1] {
                self.keys[node][index] = self.keys[node][index - 1];
                index -= 1;
            }
            self.keys[node][index] = key;
            self.key_count[node] += 1;
            return true;
        }
        while index > 0 && key < self.keys[node][index - 1] { index -= 1; }
        if self.key_count[self.children[node][index]] == MAX_NODE_KEYS {
            if !self.split_child(node, index) { return false; }
            if key > self.keys[node][index] { index += 1; }
        }
        self.insert_non_full(self.children[node][index], key)
    }

    fn insert(&mut self, key: i32) -> bool {
        if self.key_count[self.root] == MAX_NODE_KEYS {
            if self.used_nodes + 1 >= MAX_NODE_COUNT { return false; }
            let old_root = self.root;
            let root = self.used_nodes;
            self.used_nodes += 1;
            self.leaf[root] = false;
            self.children[root][0] = old_root;
            self.root = root;
            if !self.split_child(root, 0) { return false; }
        }
        self.insert_non_full(self.root, key)
    }

    fn predecessor(&self, mut node: usize) -> i32 {
        while !self.leaf[node] { node = self.children[node][self.key_count[node]]; }
        self.keys[node][self.key_count[node] - 1]
    }

    fn successor(&self, mut node: usize) -> i32 {
        while !self.leaf[node] { node = self.children[node][0]; }
        self.keys[node][0]
    }

    fn merge(&mut self, parent: usize, index: usize) {
        let left = self.children[parent][index];
        let right = self.children[parent][index + 1];
        let mut left_count = self.key_count[left];
        self.keys[left][left_count] = self.keys[parent][index];
        left_count += 1;
        for i in 0..self.key_count[right] { self.keys[left][left_count + i] = self.keys[right][i]; }
        if !self.leaf[left] {
            for i in 0..=self.key_count[right] { self.children[left][left_count + i] = self.children[right][i]; }
        }
        self.key_count[left] = left_count + self.key_count[right];
        let parent_count = self.key_count[parent];
        for i in index + 1..parent_count { self.keys[parent][i - 1] = self.keys[parent][i]; }
        for i in index + 2..=parent_count { self.children[parent][i - 1] = self.children[parent][i]; }
        self.key_count[parent] -= 1;
    }

    fn borrow_previous(&mut self, parent: usize, index: usize) {
        let child = self.children[parent][index];
        let sibling = self.children[parent][index - 1];
        let count = self.key_count[child];
        for i in (0..count).rev() { self.keys[child][i + 1] = self.keys[child][i]; }
        if !self.leaf[child] {
            for i in (0..=count).rev() { self.children[child][i + 1] = self.children[child][i]; }
        }
        self.keys[child][0] = self.keys[parent][index - 1];
        if !self.leaf[child] { self.children[child][0] = self.children[sibling][self.key_count[sibling]]; }
        self.keys[parent][index - 1] = self.keys[sibling][self.key_count[sibling] - 1];
        self.key_count[child] += 1;
        self.key_count[sibling] -= 1;
    }

    fn borrow_next(&mut self, parent: usize, index: usize) {
        let child = self.children[parent][index];
        let sibling = self.children[parent][index + 1];
        let child_count = self.key_count[child];
        let sibling_count = self.key_count[sibling];
        self.keys[child][child_count] = self.keys[parent][index];
        if !self.leaf[child] { self.children[child][child_count + 1] = self.children[sibling][0]; }
        self.keys[parent][index] = self.keys[sibling][0];
        for i in 1..sibling_count { self.keys[sibling][i - 1] = self.keys[sibling][i]; }
        if !self.leaf[sibling] {
            for i in 1..=sibling_count { self.children[sibling][i - 1] = self.children[sibling][i]; }
        }
        self.key_count[child] += 1;
        self.key_count[sibling] -= 1;
    }

    fn fill(&mut self, parent: usize, index: usize) {
        if index > 0 && self.key_count[self.children[parent][index - 1]] >= MIN_DEGREE {
            self.borrow_previous(parent, index);
        } else if index < self.key_count[parent] && self.key_count[self.children[parent][index + 1]] >= MIN_DEGREE {
            self.borrow_next(parent, index);
        } else {
            self.merge(parent, if index < self.key_count[parent] { index } else { index - 1 });
        }
    }

    fn delete_from(&mut self, node: usize, key: i32) -> bool {
        let mut index = 0;
        while index < self.key_count[node] && self.keys[node][index] < key { index += 1; }
        if index < self.key_count[node] && self.keys[node][index] == key {
            if self.leaf[node] {
                for i in index + 1..self.key_count[node] { self.keys[node][i - 1] = self.keys[node][i]; }
                self.key_count[node] -= 1;
            } else {
                let left = self.children[node][index];
                let right = self.children[node][index + 1];
                if self.key_count[left] >= MIN_DEGREE {
                    let replacement = self.predecessor(left);
                    self.keys[node][index] = replacement;
                    return self.delete_from(left, replacement);
                }
                if self.key_count[right] >= MIN_DEGREE {
                    let replacement = self.successor(right);
                    self.keys[node][index] = replacement;
                    return self.delete_from(right, replacement);
                }
                self.merge(node, index);
                return self.delete_from(left, key);
            }
            return true;
        }
        if self.leaf[node] { return false; }
        let was_last = index == self.key_count[node];
        if self.key_count[self.children[node][index]] < MIN_DEGREE { self.fill(node, index); }
        if was_last && index > self.key_count[node] { index -= 1; }
        self.delete_from(self.children[node][index], key)
    }

    fn delete(&mut self, key: i32) -> bool {
        if !self.delete_from(self.root, key) { return false; }
        if self.key_count[self.root] == 0 && !self.leaf[self.root] { self.root = self.children[self.root][0]; }
        true
    }

    fn traverse(&self, node: usize, result: &mut [i64; MAX_OUTPUT_VALUES], length: &mut usize) {
        for i in 0..self.key_count[node] {
            if !self.leaf[node] { self.traverse(self.children[node][i], result, length); }
            result[*length] = self.keys[node][i] as i64;
            *length += 1;
        }
        if !self.leaf[node] { self.traverse(self.children[node][self.key_count[node]], result, length); }
    }
}

#[no_mangle]
pub unsafe extern "C" fn btree_unique_key_set(input: *const i64, length: usize, output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 3 || length > 4096 { return -1; }
    let values = unsafe { core::slice::from_raw_parts(input, length) };
    if !(0..=MAX_INSERTS as i64).contains(&values[0]) { return -1; }
    let insert_count = values[0] as usize;
    let query_offset = 1 + insert_count;
    if query_offset >= length || !(0..=MAX_QUERIES as i64).contains(&values[query_offset]) { return -1; }
    let query_count = values[query_offset] as usize;
    let delete_count_offset = query_offset + 1 + query_count;
    if delete_count_offset >= length || !(0..=MAX_DELETES as i64).contains(&values[delete_count_offset]) { return -1; }
    let delete_count = values[delete_count_offset] as usize;
    if length != 3 + insert_count + query_count + delete_count { return -1; }

    let mut tree = BTree::new();
    for &raw in &values[1..1 + insert_count] {
        if raw < i32::MIN as i64 || raw > i32::MAX as i64 { return -1; }
        let key = raw as i32;
        if tree.search(key) || !tree.insert(key) { return -1; }
    }
    let mut result = [0i64; MAX_OUTPUT_VALUES];
    let mut result_length = 0usize;
    result[result_length] = query_count as i64;
    result_length += 1;
    let query_start = query_offset + 1;
    for &raw in &values[query_start..query_start + query_count] {
        if raw < i32::MIN as i64 || raw > i32::MAX as i64 { return -1; }
        result[result_length] = i64::from(tree.search(raw as i32));
        result_length += 1;
    }
    let delete_start = delete_count_offset + 1;
    for &raw in &values[delete_start..delete_start + delete_count] {
        if raw < i32::MIN as i64 || raw > i32::MAX as i64 || !tree.delete(raw as i32) { return -1; }
    }
    let count_slot = result_length;
    result_length += 1;
    tree.traverse(tree.root, &mut result, &mut result_length);
    result[count_slot] = (result_length - count_slot - 1) as i64;
    let bytes = result_length * 8;
    if output.is_null() || capacity < bytes { return -2; }
    let destination = unsafe { core::slice::from_raw_parts_mut(output, bytes) };
    for (index, value) in result[..result_length].iter().enumerate() {
        destination[index * 8..index * 8 + 8].copy_from_slice(&value.to_le_bytes());
    }
    bytes as i64
}
