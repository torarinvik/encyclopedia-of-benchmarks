const MAX_TEXT_LENGTH: usize = 64;
const MAX_INPUT_LENGTH: usize = 66;
const MAX_SYMBOLS: usize = MAX_TEXT_LENGTH + 1;
const MAX_NODES: usize = 130;

#[derive(Clone, Copy)]
struct SuffixNode {
    edge_start: usize,
    edge_end: usize,
    suffix_link: usize,
    suffix_start: usize,
    leaf: bool,
    children: [usize; 5],
}

impl SuffixNode {
    const fn empty() -> Self {
        Self {
            edge_start: 0,
            edge_end: 0,
            suffix_link: 0,
            suffix_start: 0,
            leaf: false,
            children: [MAX_NODES; 5],
        }
    }
}

struct Accumulator {
    rank: i64,
    checksum: i64,
    distinct_substrings: i64,
}

struct UkkonenState {
    symbols: [usize; MAX_SYMBOLS],
    symbol_count: usize,
    leaf_end: usize,
    nodes: [SuffixNode; MAX_NODES],
    node_count: usize,
}

impl UkkonenState {
    fn new_node(&mut self, edge_start: usize, edge_end: usize, leaf: bool, suffix_start: usize) -> usize {
        if self.node_count >= MAX_NODES { return MAX_NODES; }
        let node = self.node_count;
        self.node_count += 1;
        self.nodes[node] = SuffixNode { edge_start, edge_end, suffix_start, leaf, ..SuffixNode::empty() };
        node
    }

    fn edge_length(&self, node: usize) -> usize {
        let end = if self.nodes[node].leaf { self.leaf_end + 1 } else { self.nodes[node].edge_end };
        end - self.nodes[node].edge_start
    }

    fn build_online_tree(&mut self) -> bool {
        let root = self.new_node(0, 0, false, 0);
        if root != 0 { return false; }
        self.nodes[root].suffix_link = root;

        let mut active_node = root;
        let mut active_edge = 0_usize;
        let mut active_length = 0_usize;
        let mut remaining = 0_usize;
        self.leaf_end = 0;

        for position in 0..self.symbol_count {
            self.leaf_end = position;
            remaining += 1;
            let mut last_internal = MAX_NODES;

            while remaining > 0 {
                if active_length == 0 { active_edge = position; }
                let active_symbol = self.symbols[active_edge];
                let mut next = self.nodes[active_node].children[active_symbol];

                if next == MAX_NODES {
                    let suffix_start = position - remaining + 1;
                    next = self.new_node(position, 0, true, suffix_start);
                    if next == MAX_NODES { return false; }
                    self.nodes[active_node].children[active_symbol] = next;
                    if last_internal != MAX_NODES {
                        self.nodes[last_internal].suffix_link = active_node;
                        last_internal = MAX_NODES;
                    }
                } else {
                    let next_length = self.edge_length(next);
                    if active_length >= next_length {
                        active_edge += next_length;
                        active_length -= next_length;
                        active_node = next;
                        continue;
                    }

                    let next_start = self.nodes[next].edge_start;
                    if self.symbols[next_start + active_length] == self.symbols[position] {
                        if last_internal != MAX_NODES && active_node != root {
                            self.nodes[last_internal].suffix_link = active_node;
                            last_internal = MAX_NODES;
                        }
                        active_length += 1;
                        break;
                    }

                    let split = self.new_node(next_start, next_start + active_length, false, 0);
                    if split == MAX_NODES { return false; }
                    self.nodes[active_node].children[active_symbol] = split;
                    self.nodes[next].edge_start += active_length;
                    let old_symbol = self.symbols[self.nodes[next].edge_start];
                    self.nodes[split].children[old_symbol] = next;

                    let suffix_start = position - remaining + 1;
                    let leaf = self.new_node(position, 0, true, suffix_start);
                    if leaf == MAX_NODES { return false; }
                    self.nodes[split].children[self.symbols[position]] = leaf;
                    if last_internal != MAX_NODES { self.nodes[last_internal].suffix_link = split; }
                    last_internal = split;
                }

                remaining -= 1;
                if active_node == root && active_length > 0 {
                    active_length -= 1;
                    active_edge = position - remaining + 1;
                } else if active_node != root {
                    active_node = self.nodes[active_node].suffix_link;
                }
            }
        }
        true
    }

    fn push_token(accumulator: &mut Accumulator, token: i64) {
        accumulator.rank += 1;
        accumulator.checksum += accumulator.rank * token;
    }

    fn emit_node(&self, node: usize, is_root: bool, accumulator: &mut Accumulator) {
        if is_root { Self::push_token(accumulator, 0); }
        for symbol in 0..5 {
            let child = self.nodes[node].children[symbol];
            if child == MAX_NODES { continue; }
            let edge_end = if self.nodes[child].leaf { self.leaf_end + 1 } else { self.nodes[child].edge_end };
            let edge_start = self.nodes[child].edge_start;
            let edge_length = edge_end - edge_start;
            Self::push_token(accumulator, 1);
            Self::push_token(accumulator, edge_length as i64);
            for index in edge_start..edge_end {
                let value = self.symbols[index];
                Self::push_token(accumulator, value as i64 + 1);
                if value != 4 { accumulator.distinct_substrings += 1; }
            }
            if self.nodes[child].leaf {
                Self::push_token(accumulator, 2);
                Self::push_token(accumulator, self.nodes[child].suffix_start as i64 + 1);
            } else {
                Self::push_token(accumulator, 3);
                self.emit_node(child, false, accumulator);
                Self::push_token(accumulator, 4);
            }
        }
        if is_root { Self::push_token(accumulator, 4); }
    }
}

#[no_mangle]
pub unsafe extern "C" fn ukkonen_suffix_tree(input_opt: *const i64, length: usize) -> i64 {
    if input_opt.is_null() || length < 1 || length > MAX_INPUT_LENGTH { return -1; }
    let input = std::slice::from_raw_parts(input_opt, length);
    let text_length_value = input[0];
    if text_length_value < 0 || text_length_value > MAX_TEXT_LENGTH as i64 { return -1; }
    let text_length = text_length_value as usize;
    if length != text_length + 1 { return -1; }

    let mut state = UkkonenState {
        symbols: [0; MAX_SYMBOLS],
        symbol_count: text_length + 1,
        leaf_end: 0,
        nodes: [SuffixNode::empty(); MAX_NODES],
        node_count: 0,
    };
    for index in 0..text_length {
        let symbol = input[index + 1];
        if !(0..=3).contains(&symbol) { return -1; }
        state.symbols[index] = symbol as usize;
    }
    state.symbols[text_length] = 4;
    if !state.build_online_tree() { return -1; }

    let mut accumulator = Accumulator { rank: 0, checksum: 0, distinct_substrings: 0 };
    state.emit_node(0, true, &mut accumulator);
    (state.node_count as i64) * (1_i64 << 44)
        + (accumulator.distinct_substrings << 32)
        + accumulator.checksum
}
