const MAX_OPERATIONS: usize = 128;
const MAX_NODES: usize = 2049;
const MAX_PARSEABLE_INPUT_LENGTH: usize = 258;
const MAX_OUTPUT_WORDS: usize = 130;
const NO_CHILD: usize = usize::MAX;

#[derive(Clone, Copy)]
struct Node {
    keys: [i64; 3],
    children: [usize; 4],
    key_count: usize,
    leaf: bool,
}

impl Node {
    const fn empty() -> Self {
        Self { keys: [0; 3], children: [NO_CHILD; 4], key_count: 0, leaf: true }
    }
}

struct Tree {
    nodes: [Node; MAX_NODES],
    node_count: usize,
    root: Option<usize>,
    final_keys: [i64; MAX_OPERATIONS],
    final_count: usize,
}

impl Tree {
    fn new() -> Self {
        Self {
            nodes: [Node::empty(); MAX_NODES],
            node_count: 0,
            root: None,
            final_keys: [0; MAX_OPERATIONS],
            final_count: 0,
        }
    }

    fn new_node(&mut self, leaf: bool) -> usize {
        let index = self.node_count;
        self.node_count += 1;
        self.nodes[index] = Node { leaf, ..Node::empty() };
        index
    }

    fn contains(&self, node_index: Option<usize>, key: i64) -> bool {
        let Some(index) = node_index else { return false };
        let node = self.nodes[index];
        let mut slot = 0;
        while slot < node.key_count && key > node.keys[slot] { slot += 1; }
        if slot < node.key_count && key == node.keys[slot] { return true; }
        !node.leaf && self.contains(Some(node.children[slot]), key)
    }

    fn split_child(&mut self, parent_index: usize, child_slot: usize) {
        let child_index = self.nodes[parent_index].children[child_slot];
        let child = self.nodes[child_index];
        let right_index = self.new_node(child.leaf);
        self.nodes[right_index].key_count = 1;
        self.nodes[right_index].keys[0] = child.keys[2];
        if !child.leaf {
            self.nodes[right_index].children[0] = child.children[2];
            self.nodes[right_index].children[1] = child.children[3];
        }
        let middle = child.keys[1];
        self.nodes[child_index].key_count = 1;
        let parent_count = self.nodes[parent_index].key_count;
        for slot in (child_slot..parent_count).rev() {
            self.nodes[parent_index].keys[slot + 1] = self.nodes[parent_index].keys[slot];
        }
        for slot in (child_slot + 1..=parent_count).rev() {
            self.nodes[parent_index].children[slot + 1] = self.nodes[parent_index].children[slot];
        }
        self.nodes[parent_index].keys[child_slot] = middle;
        self.nodes[parent_index].children[child_slot + 1] = right_index;
        self.nodes[parent_index].key_count += 1;
    }

    fn insert_nonfull(&mut self, node_index: usize, key: i64) {
        let node = self.nodes[node_index];
        let mut slot = node.key_count;
        if node.leaf {
            while slot > 0 && key < self.nodes[node_index].keys[slot - 1] {
                self.nodes[node_index].keys[slot] = self.nodes[node_index].keys[slot - 1];
                slot -= 1;
            }
            self.nodes[node_index].keys[slot] = key;
            self.nodes[node_index].key_count += 1;
            return;
        }
        while slot > 0 && key < node.keys[slot - 1] { slot -= 1; }
        let mut child_index = self.nodes[node_index].children[slot];
        if self.nodes[child_index].key_count == 3 {
            self.split_child(node_index, slot);
            if key > self.nodes[node_index].keys[slot] { slot += 1; }
            child_index = self.nodes[node_index].children[slot];
        }
        self.insert_nonfull(child_index, key);
    }

    fn insert(&mut self, key: i64) {
        if self.contains(self.root, key) { return; }
        let Some(root_index) = self.root else {
            let index = self.new_node(true);
            self.nodes[index].keys[0] = key;
            self.nodes[index].key_count = 1;
            self.root = Some(index);
            return;
        };
        if self.nodes[root_index].key_count == 3 {
            let new_root = self.new_node(false);
            self.nodes[new_root].children[0] = root_index;
            self.root = Some(new_root);
            self.split_child(new_root, 0);
        }
        self.insert_nonfull(self.root.unwrap(), key);
    }

    fn predecessor(&self, mut node_index: usize) -> i64 {
        while !self.nodes[node_index].leaf {
            node_index = self.nodes[node_index].children[self.nodes[node_index].key_count];
        }
        self.nodes[node_index].keys[self.nodes[node_index].key_count - 1]
    }

    fn successor(&self, mut node_index: usize) -> i64 {
        while !self.nodes[node_index].leaf { node_index = self.nodes[node_index].children[0]; }
        self.nodes[node_index].keys[0]
    }

    fn merge_children(&mut self, parent_index: usize, key_slot: usize) -> usize {
        let left_index = self.nodes[parent_index].children[key_slot];
        let right_index = self.nodes[parent_index].children[key_slot + 1];
        let left_count = self.nodes[left_index].key_count;
        let right_count = self.nodes[right_index].key_count;
        self.nodes[left_index].keys[left_count] = self.nodes[parent_index].keys[key_slot];
        for slot in 0..right_count {
            self.nodes[left_index].keys[left_count + 1 + slot] = self.nodes[right_index].keys[slot];
        }
        if !self.nodes[left_index].leaf {
            for slot in 0..=right_count {
                self.nodes[left_index].children[left_count + 1 + slot] = self.nodes[right_index].children[slot];
            }
        }
        self.nodes[left_index].key_count = left_count + 1 + right_count;
        let parent_count = self.nodes[parent_index].key_count;
        for slot in key_slot..parent_count - 1 {
            self.nodes[parent_index].keys[slot] = self.nodes[parent_index].keys[slot + 1];
        }
        for slot in key_slot + 1..parent_count {
            self.nodes[parent_index].children[slot] = self.nodes[parent_index].children[slot + 1];
        }
        self.nodes[parent_index].key_count -= 1;
        left_index
    }

    fn borrow_from_previous(&mut self, parent_index: usize, child_slot: usize) {
        let child_index = self.nodes[parent_index].children[child_slot];
        let sibling_index = self.nodes[parent_index].children[child_slot - 1];
        let child_count = self.nodes[child_index].key_count;
        let sibling_count = self.nodes[sibling_index].key_count;
        for slot in (0..child_count).rev() { self.nodes[child_index].keys[slot + 1] = self.nodes[child_index].keys[slot]; }
        if !self.nodes[child_index].leaf {
            for slot in (0..=child_count).rev() {
                self.nodes[child_index].children[slot + 1] = self.nodes[child_index].children[slot];
            }
            self.nodes[child_index].children[0] = self.nodes[sibling_index].children[sibling_count];
        }
        self.nodes[child_index].keys[0] = self.nodes[parent_index].keys[child_slot - 1];
        self.nodes[parent_index].keys[child_slot - 1] = self.nodes[sibling_index].keys[sibling_count - 1];
        self.nodes[child_index].key_count += 1;
        self.nodes[sibling_index].key_count -= 1;
    }

    fn borrow_from_next(&mut self, parent_index: usize, child_slot: usize) {
        let child_index = self.nodes[parent_index].children[child_slot];
        let sibling_index = self.nodes[parent_index].children[child_slot + 1];
        let child_count = self.nodes[child_index].key_count;
        let sibling_count = self.nodes[sibling_index].key_count;
        self.nodes[child_index].keys[child_count] = self.nodes[parent_index].keys[child_slot];
        if !self.nodes[child_index].leaf {
            self.nodes[child_index].children[child_count + 1] = self.nodes[sibling_index].children[0];
        }
        self.nodes[parent_index].keys[child_slot] = self.nodes[sibling_index].keys[0];
        for slot in 0..sibling_count - 1 { self.nodes[sibling_index].keys[slot] = self.nodes[sibling_index].keys[slot + 1]; }
        if !self.nodes[sibling_index].leaf {
            for slot in 0..sibling_count { self.nodes[sibling_index].children[slot] = self.nodes[sibling_index].children[slot + 1]; }
        }
        self.nodes[child_index].key_count += 1;
        self.nodes[sibling_index].key_count -= 1;
    }

    fn remove_from_node(&mut self, node_index: usize, key: i64) {
        let mut key_slot = 0;
        while key_slot < self.nodes[node_index].key_count && self.nodes[node_index].keys[key_slot] < key { key_slot += 1; }
        let found = key_slot < self.nodes[node_index].key_count && self.nodes[node_index].keys[key_slot] == key;
        if found {
            if self.nodes[node_index].leaf {
                let count = self.nodes[node_index].key_count;
                for slot in key_slot..count - 1 { self.nodes[node_index].keys[slot] = self.nodes[node_index].keys[slot + 1]; }
                self.nodes[node_index].key_count -= 1;
                return;
            }
            let left_index = self.nodes[node_index].children[key_slot];
            let right_index = self.nodes[node_index].children[key_slot + 1];
            if self.nodes[left_index].key_count >= 2 {
                let replacement = self.predecessor(left_index);
                self.nodes[node_index].keys[key_slot] = replacement;
                self.remove_from_node(left_index, replacement);
            } else if self.nodes[right_index].key_count >= 2 {
                let replacement = self.successor(right_index);
                self.nodes[node_index].keys[key_slot] = replacement;
                self.remove_from_node(right_index, replacement);
            } else {
                let merged = self.merge_children(node_index, key_slot);
                self.remove_from_node(merged, key);
            }
            return;
        }
        if self.nodes[node_index].leaf { return; }
        let mut child_slot = key_slot;
        let mut child_index = self.nodes[node_index].children[child_slot];
        if self.nodes[child_index].key_count == 1 {
            if child_slot > 0 && self.nodes[self.nodes[node_index].children[child_slot - 1]].key_count >= 2 {
                self.borrow_from_previous(node_index, child_slot);
            } else if child_slot < self.nodes[node_index].key_count &&
                self.nodes[self.nodes[node_index].children[child_slot + 1]].key_count >= 2 {
                self.borrow_from_next(node_index, child_slot);
            } else if child_slot < self.nodes[node_index].key_count {
                child_index = self.merge_children(node_index, child_slot);
            } else {
                child_slot -= 1;
                child_index = self.merge_children(node_index, child_slot);
            }
        }
        self.remove_from_node(child_index, key);
    }

    fn remove(&mut self, key: i64) -> bool {
        if !self.contains(self.root, key) { return false; }
        let root = self.root.unwrap();
        self.remove_from_node(root, key);
        if self.nodes[root].key_count == 0 {
            self.root = if self.nodes[root].leaf { None } else { Some(self.nodes[root].children[0]) };
        }
        true
    }

    fn traverse(&mut self, node_index: Option<usize>) {
        let Some(index) = node_index else { return };
        let node = self.nodes[index];
        for slot in 0..node.key_count {
            if !node.leaf { self.traverse(Some(node.children[slot])); }
            self.final_keys[self.final_count] = node.keys[slot];
            self.final_count += 1;
        }
        if !node.leaf { self.traverse(Some(node.children[node.key_count])); }
    }
}

fn write_i64_le(output: &mut [u8], offset: usize, value: i64) {
    output[offset..offset + 8].copy_from_slice(&value.to_le_bytes());
}

#[no_mangle]
pub extern "C" fn tree_234(input: *const i64, input_length: usize, output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || input_length == 0 || input_length > MAX_PARSEABLE_INPUT_LENGTH { return -1; }
    let values = unsafe { std::slice::from_raw_parts(input, input_length) };
    if values[0] < 0 || values[0] > MAX_OPERATIONS as i64 { return -1; }
    let operation_count = values[0] as usize;
    if input_length != 1 + 2 * operation_count { return -1; }
    for operation in 0..operation_count {
        let code = values[1 + 2 * operation];
        if code != 0 && code != 1 { return -1; }
    }

    let mut tree = Tree::new();
    let mut remove_results = [0i64; MAX_OPERATIONS];
    let mut remove_count = 0usize;
    for operation in 0..operation_count {
        let code = values[1 + 2 * operation];
        let key = values[2 + 2 * operation];
        if code == 0 { tree.insert(key); }
        else {
            remove_results[remove_count] = if tree.remove(key) { 1 } else { 0 };
            remove_count += 1;
        }
    }
    tree.traverse(tree.root);

    let mut words = [0i64; MAX_OUTPUT_WORDS];
    words[0] = remove_count as i64;
    words[1..1 + remove_count].copy_from_slice(&remove_results[..remove_count]);
    words[1 + remove_count] = tree.final_count as i64;
    let mut word_count = 2 + remove_count;
    for key in tree.final_keys[..tree.final_count].iter() {
        words[word_count] = *key;
        word_count += 1;
    }
    let output_bytes = word_count * 8;
    if output_bytes > MAX_OUTPUT_WORDS * 8 { return -1; }
    if output.is_null() || capacity < output_bytes { return -2; }
    let output_slice = unsafe { std::slice::from_raw_parts_mut(output, output_bytes) };
    for (index, word) in words[..word_count].iter().enumerate() { write_i64_le(output_slice, index * 8, *word); }
    output_bytes as i64
}
