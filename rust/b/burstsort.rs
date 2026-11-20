const MAX_STRINGS: usize = 16;
const MAX_STRING_LENGTH: usize = 8;
const MAX_INPUT_WORDS: usize = 145;
const MAX_TRIE_NODES: usize = 129;
const BUCKET_THRESHOLD: usize = 3;

#[derive(Clone, Copy)]
struct BurstNode {
    depth: usize,
    burst: bool,
    children: [usize; 4],
    bucket: [usize; MAX_STRINGS],
    bucket_count: usize,
    terminal: [usize; MAX_STRINGS],
    terminal_count: usize,
}

impl BurstNode {
    const fn empty() -> Self {
        Self {
            depth: 0,
            burst: false,
            children: [MAX_TRIE_NODES; 4],
            bucket: [0; MAX_STRINGS],
            bucket_count: 0,
            terminal: [0; MAX_STRINGS],
            terminal_count: 0,
        }
    }
}

struct BurstState {
    nodes: [BurstNode; MAX_TRIE_NODES],
    node_count: usize,
    lengths: [usize; MAX_STRINGS],
    bytes: [[u8; MAX_STRING_LENGTH]; MAX_STRINGS],
}

impl BurstState {
    fn new_node(&mut self, depth: usize) -> usize {
        if self.node_count >= MAX_TRIE_NODES { return MAX_TRIE_NODES; }
        let node = self.node_count;
        self.node_count += 1;
        self.nodes[node] = BurstNode { depth, ..BurstNode::empty() };
        node
    }

    fn add_to_child(&mut self, node: usize, string_id: usize) -> bool {
        let depth = self.nodes[node].depth;
        let symbol = self.bytes[string_id][depth] as usize;
        let mut child = self.nodes[node].children[symbol];
        if child == MAX_TRIE_NODES {
            child = self.new_node(depth + 1);
            if child == MAX_TRIE_NODES { return false; }
            self.nodes[node].children[symbol] = child;
        }
        self.add_string(child, string_id)
    }

    fn add_string(&mut self, node: usize, string_id: usize) -> bool {
        let depth = self.nodes[node].depth;
        if self.lengths[string_id] == depth {
            let terminal_count = self.nodes[node].terminal_count;
            if terminal_count >= MAX_STRINGS { return false; }
            self.nodes[node].terminal[terminal_count] = string_id;
            self.nodes[node].terminal_count = terminal_count + 1;
            return true;
        }
        if self.nodes[node].burst {
            return self.add_to_child(node, string_id);
        }

        let bucket_count = self.nodes[node].bucket_count;
        if bucket_count < BUCKET_THRESHOLD {
            self.nodes[node].bucket[bucket_count] = string_id;
            self.nodes[node].bucket_count = bucket_count + 1;
            return true;
        }

        let mut pending = [0_usize; MAX_STRINGS];
        for index in 0..bucket_count { pending[index] = self.nodes[node].bucket[index]; }
        self.nodes[node].bucket_count = 0;
        self.nodes[node].burst = true;
        for index in 0..bucket_count {
            if !self.add_to_child(node, pending[index]) { return false; }
        }
        self.add_to_child(node, string_id)
    }

    fn less_strings(&self, left: usize, right: usize) -> bool {
        let common_length = self.lengths[left].min(self.lengths[right]);
        for index in 0..common_length {
            if self.bytes[left][index] != self.bytes[right][index] {
                return self.bytes[left][index] < self.bytes[right][index];
            }
        }
        self.lengths[left] < self.lengths[right]
    }

    fn key_code(&self, string_id: usize) -> i64 {
        let mut code = 0_i64;
        let mut weight = 78_125_i64; // 5^(7-j), where j is measured from the string's first byte.
        for index in 0..self.lengths[string_id] {
            code += (self.bytes[string_id][index] as i64 + 1) * weight;
            weight /= 5;
        }
        code
    }

    fn emit_node(&mut self, node: usize, rank: &mut i64, checksum: &mut i64) {
        let terminal_count = self.nodes[node].terminal_count;
        for index in 0..terminal_count {
            *rank += 1;
            *checksum += *rank * self.key_code(self.nodes[node].terminal[index]);
        }
        if self.nodes[node].burst {
            for symbol in 0..4 {
                let child = self.nodes[node].children[symbol];
                if child != MAX_TRIE_NODES { self.emit_node(child, rank, checksum); }
            }
            return;
        }

        let bucket_count = self.nodes[node].bucket_count;
        for position in 1..bucket_count {
            let item = self.nodes[node].bucket[position];
            let mut insertion = position;
            while insertion > 0
                && self.less_strings(item, self.nodes[node].bucket[insertion - 1])
            {
                self.nodes[node].bucket[insertion] = self.nodes[node].bucket[insertion - 1];
                insertion -= 1;
            }
            self.nodes[node].bucket[insertion] = item;
        }
        for index in 0..bucket_count {
            *rank += 1;
            *checksum += *rank * self.key_code(self.nodes[node].bucket[index]);
        }
    }
}

#[no_mangle]
pub unsafe extern "C" fn burstsort(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 1 || length > MAX_INPUT_WORDS { return -1; }
    let string_count_value = *input;
    if !(0..=MAX_STRINGS as i64).contains(&string_count_value) { return -1; }
    let string_count = string_count_value as usize;
    let mut state = BurstState {
        nodes: [BurstNode::empty(); MAX_TRIE_NODES],
        node_count: 0,
        lengths: [0; MAX_STRINGS],
        bytes: [[0; MAX_STRING_LENGTH]; MAX_STRINGS],
    };

    let mut position = 1_usize;
    for string_id in 0..string_count {
        if position >= length { return -1; }
        let string_length_value = *input.add(position);
        position += 1;
        if !(0..=MAX_STRING_LENGTH as i64).contains(&string_length_value) { return -1; }
        let string_length = string_length_value as usize;
        if string_length > length - position { return -1; }
        state.lengths[string_id] = string_length;
        for byte_index in 0..string_length {
            let byte = *input.add(position);
            position += 1;
            if !(0..=3).contains(&byte) { return -1; }
            state.bytes[string_id][byte_index] = byte as u8;
        }
    }
    if position != length { return -1; }

    let root = state.new_node(0);
    if root == MAX_TRIE_NODES { return -1; }
    for string_id in 0..string_count {
        if !state.add_string(root, string_id) { return -1; }
    }
    let mut rank = 0_i64;
    let mut checksum = 0_i64;
    state.emit_node(root, &mut rank, &mut checksum);
    checksum
}
