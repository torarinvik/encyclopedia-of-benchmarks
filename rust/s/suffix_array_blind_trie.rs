use core::slice;

const MAX_TEXT_LENGTH: usize = 32;
const MAX_INPUT_LENGTH: usize = 34;
const MAX_NODES: usize = 64;

#[derive(Clone, Copy)]
struct TrieNode {
    is_leaf: bool,
    split_pos: i32,
    leaf_start: i32,
    edge_symbol: i32,
    first_child: i32,
    next_sibling: i32,
}

impl TrieNode {
    const fn empty() -> Self {
        Self { is_leaf: false, split_pos: 0, leaf_start: -1,
            edge_symbol: 0, first_child: -1, next_sibling: -1 }
    }
}

struct BlindTrie {
    node: [TrieNode; MAX_NODES],
    count: i32,
    root: i32,
}

impl BlindTrie {
    fn new() -> Self {
        Self { node: [TrieNode::empty(); MAX_NODES], count: 0, root: -1 }
    }

    fn allocate(&mut self, is_leaf: bool, value: i32) -> i32 {
        let index = self.count;
        self.count += 1;
        self.node[index as usize].is_leaf = is_leaf;
        self.node[index as usize].split_pos = if is_leaf { 0 } else { value };
        self.node[index as usize].leaf_start = if is_leaf { value } else { -1 };
        index
    }

    fn find_child(&self, parent: i32, symbol: i32) -> i32 {
        let mut child = self.node[parent as usize].first_child;
        while child >= 0 {
            let item = &self.node[child as usize];
            if item.edge_symbol == symbol { return child; }
            if item.edge_symbol > symbol { return -1; }
            child = item.next_sibling;
        }
        -1
    }

    fn link_child(&mut self, parent: i32, child: i32) {
        let symbol = self.node[child as usize].edge_symbol;
        let mut previous = -1;
        let mut cursor = self.node[parent as usize].first_child;
        while cursor >= 0 && self.node[cursor as usize].edge_symbol < symbol {
            previous = cursor;
            cursor = self.node[cursor as usize].next_sibling;
        }
        self.node[child as usize].next_sibling = cursor;
        if previous < 0 {
            self.node[parent as usize].first_child = child;
        } else {
            self.node[previous as usize].next_sibling = child;
        }
    }

    fn replace_child(&mut self, parent: i32, old_child: i32, new_child: i32) {
        let mut previous = -1;
        let mut cursor = self.node[parent as usize].first_child;
        while cursor != old_child {
            previous = cursor;
            cursor = self.node[cursor as usize].next_sibling;
        }
        self.node[new_child as usize].edge_symbol = self.node[old_child as usize].edge_symbol;
        self.node[new_child as usize].next_sibling = self.node[old_child as usize].next_sibling;
        if previous < 0 {
            self.node[parent as usize].first_child = new_child;
        } else {
            self.node[previous as usize].next_sibling = new_child;
        }
    }
}

fn symbol_at(input: &[i64], n: i32, start: i32, depth: i32) -> i32 {
    let position = start + depth;
    if position >= n { 0 } else { input[(position + 1) as usize] as i32 + 1 }
}

fn common_prefix(input: &[i64], n: i32, left: i32, right: i32) -> i32 {
    let mut depth = 0;
    while symbol_at(input, n, left, depth) == symbol_at(input, n, right, depth) {
        depth += 1;
    }
    depth
}

fn insert_suffix(trie: &mut BlindTrie, input: &[i64], n: i32, start: i32) {
    let fresh = trie.allocate(true, start);
    if trie.node[trie.root as usize].is_leaf {
        let old = trie.root;
        let depth = common_prefix(input, n, trie.node[old as usize].leaf_start, start);
        let middle = trie.allocate(false, depth);
        trie.node[old as usize].edge_symbol = symbol_at(input, n, trie.node[old as usize].leaf_start, depth);
        trie.node[fresh as usize].edge_symbol = symbol_at(input, n, start, depth);
        trie.link_child(middle, old);
        trie.link_child(middle, fresh);
        trie.root = middle;
        return;
    }

    let mut leaf = trie.root;
    while !trie.node[leaf as usize].is_leaf {
        let symbol = symbol_at(input, n, start, trie.node[leaf as usize].split_pos);
        let mut child = trie.find_child(leaf, symbol);
        if child < 0 { child = trie.node[leaf as usize].first_child; }
        leaf = child;
    }
    let old_start = trie.node[leaf as usize].leaf_start;
    let depth = common_prefix(input, n, start, old_start);
    let mut parent = -1;
    let mut current = trie.root;
    while !trie.node[current as usize].is_leaf
        && trie.node[current as usize].split_pos < depth
    {
        let symbol = symbol_at(input, n, start, trie.node[current as usize].split_pos);
        let mut child = trie.find_child(current, symbol);
        if child < 0 { child = trie.node[current as usize].first_child; }
        parent = current;
        current = child;
    }
    if !trie.node[current as usize].is_leaf
        && trie.node[current as usize].split_pos == depth
    {
        trie.node[fresh as usize].edge_symbol = symbol_at(input, n, start, depth);
        trie.link_child(current, fresh);
        return;
    }

    let middle = trie.allocate(false, depth);
    if parent < 0 {
        trie.root = middle;
    } else {
        trie.replace_child(parent, current, middle);
    }
    trie.node[current as usize].edge_symbol = symbol_at(input, n, old_start, depth);
    trie.node[fresh as usize].edge_symbol = symbol_at(input, n, start, depth);
    trie.link_child(middle, current);
    trie.link_child(middle, fresh);
}

fn ordered_leaves(trie: &BlindTrie, output: &mut [i32; MAX_TEXT_LENGTH]) -> usize {
    let mut stack = [0i32; MAX_NODES];
    let mut top = 0usize;
    let mut count = 0usize;
    stack[top] = trie.root;
    top += 1;
    while top > 0 {
        top -= 1;
        let node = stack[top];
        if trie.node[node as usize].is_leaf {
            output[count] = trie.node[node as usize].leaf_start;
            count += 1;
            continue;
        }
        let mut children = [0i32; MAX_TEXT_LENGTH];
        let mut child_count = 0usize;
        let mut child = trie.node[node as usize].first_child;
        while child >= 0 {
            children[child_count] = child;
            child_count += 1;
            child = trie.node[child as usize].next_sibling;
        }
        while child_count > 0 {
            child_count -= 1;
            stack[top] = children[child_count];
            top += 1;
        }
    }
    count
}

#[no_mangle]
pub unsafe extern "C" fn suffix_array_blind_trie(
    values: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if values.is_null() || length < 1 || length > MAX_INPUT_LENGTH { return -1; }
    let input = slice::from_raw_parts(values, length);
    let count_value = input[0];
    if count_value < 0 || count_value > MAX_TEXT_LENGTH as i64 { return -1; }
    let n = count_value as usize;
    if length != n + 1 || input[1..].iter().any(|&value| !(0..=255).contains(&value)) {
        return -1;
    }
    let output_bytes = n * 8;
    if output.is_null() || capacity < output_bytes { return -2; }
    if n == 0 { return 0; }

    let mut trie = BlindTrie::new();
    trie.root = trie.allocate(true, 0);
    for start in 1..n { insert_suffix(&mut trie, input, n as i32, start as i32); }
    let mut order = [0i32; MAX_TEXT_LENGTH];
    let order_len = ordered_leaves(&trie, &mut order);
    let output = slice::from_raw_parts_mut(output, output_bytes);
    for index in 0..order_len {
        let offset = index * 8;
        output[offset..offset + 8].copy_from_slice(&(order[index] as i64).to_le_bytes());
    }
    output_bytes as i64
}
