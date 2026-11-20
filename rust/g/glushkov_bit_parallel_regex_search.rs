const MAX_TEXT: usize = 24;
const MAX_PATTERN: usize = 32;
const MAX_POSITIONS: usize = 8;
const MAX_NODES: usize = 64;
const POSITION: u8 = 1;
const CONCAT: u8 = 2;
const ALT: u8 = 3;
const STAR: u8 = 4;

#[derive(Clone, Copy, Default)]
struct Node { kind: u8, left: u8, right: u8, position: u8 }

struct Parser<'a> {
    pattern: &'a [i64],
    cursor: usize,
    node_count: usize,
    position_count: usize,
    nodes: [Node; MAX_NODES],
    symbols: [u8; MAX_POSITIONS + 1],
    failed: bool,
}

impl<'a> Parser<'a> {
    fn new(pattern: &'a [i64]) -> Self {
        Self { pattern, cursor: 0, node_count: 0, position_count: 0,
            nodes: [Node::default(); MAX_NODES], symbols: [0; MAX_POSITIONS + 1], failed: false }
    }
    fn add(&mut self, kind: u8, left: u8, right: u8, position: u8) -> u8 {
        if self.node_count >= MAX_NODES { self.failed = true; return 0; }
        let result = self.node_count as u8;
        self.node_count += 1;
        self.nodes[result as usize] = Node { kind, left, right, position };
        result
    }
    fn expression(&mut self) -> u8 {
        let mut result = self.concatenation();
        while !self.failed && self.cursor < self.pattern.len() && self.pattern[self.cursor] == 124 {
            self.cursor += 1;
            let right = self.concatenation();
            result = self.add(ALT, result, right, 0);
        }
        result
    }
    fn concatenation(&mut self) -> u8 {
        if self.cursor >= self.pattern.len() || self.pattern[self.cursor] == 124 || self.pattern[self.cursor] == 41 {
            self.failed = true; return 0;
        }
        let mut result = self.repetition();
        while !self.failed && self.cursor < self.pattern.len()
            && self.pattern[self.cursor] != 124 && self.pattern[self.cursor] != 41 {
            let right = self.repetition();
            result = self.add(CONCAT, result, right, 0);
        }
        result
    }
    fn repetition(&mut self) -> u8 {
        let mut result = self.atom();
        if !self.failed && self.cursor < self.pattern.len() && self.pattern[self.cursor] == 42 {
            self.cursor += 1;
            result = self.add(STAR, result, 0, 0);
        }
        result
    }
    fn atom(&mut self) -> u8 {
        if self.cursor >= self.pattern.len() { self.failed = true; return 0; }
        let token = self.pattern[self.cursor];
        self.cursor += 1;
        if token == 40 {
            let result = self.expression();
            if self.failed || self.cursor >= self.pattern.len() || self.pattern[self.cursor] != 41 {
                self.failed = true; return 0;
            }
            self.cursor += 1;
            return result;
        }
        if token != 97 && token != 98 && token != 99 && token != 46 { self.failed = true; return 0; }
        if self.position_count >= MAX_POSITIONS { self.failed = true; return 0; }
        self.position_count += 1;
        let position = self.position_count as u8;
        self.symbols[position as usize] = token as u8;
        self.add(POSITION, 0, 0, position)
    }
}

#[no_mangle]
pub unsafe extern "C" fn glushkov_bit_parallel_regex_search(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || length < 2 || length > 58 { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    if !(0..=MAX_TEXT as i64).contains(&values[0])
        || !(1..=MAX_PATTERN as i64).contains(&values[1]) { return -1; }
    let text_len = values[0] as usize;
    let pattern_len = values[1] as usize;
    if length != 2 + text_len + pattern_len { return -1; }
    if values[2..].iter().any(|&byte| !(1..=127).contains(&byte)) { return -1; }
    let text = &values[2..2 + text_len];
    let mut parser = Parser::new(&values[2 + text_len..]);
    let root = parser.expression() as usize;
    if parser.failed || parser.cursor != pattern_len || parser.node_count == 0 { return -1; }

    let mut nullable = [false; MAX_NODES];
    let mut first = [0u16; MAX_NODES];
    let mut last = [0u16; MAX_NODES];
    let mut follow = [0u16; MAX_POSITIONS + 1];
    for i in 0..parser.node_count {
        let node = parser.nodes[i];
        let a = node.left as usize;
        let b = node.right as usize;
        match node.kind {
            POSITION => {
                let bit = 1u16 << node.position;
                first[i] = bit;
                last[i] = bit;
            }
            STAR => {
                nullable[i] = true;
                first[i] = first[a];
                last[i] = last[a];
                for p in 1..=parser.position_count {
                    if last[a] & (1u16 << p) != 0 { follow[p] |= first[a]; }
                }
            }
            ALT => {
                nullable[i] = nullable[a] || nullable[b];
                first[i] = first[a] | first[b];
                last[i] = last[a] | last[b];
            }
            _ => {
                nullable[i] = nullable[a] && nullable[b];
                first[i] = first[a] | if nullable[a] { first[b] } else { 0 };
                last[i] = last[b] | if nullable[b] { last[a] } else { 0 };
                for p in 1..=parser.position_count {
                    if last[a] & (1u16 << p) != 0 { follow[p] |= first[b]; }
                }
            }
        }
    }
    follow[0] = first[root] | 1;
    let mut transitions = [0u16; 1 << (MAX_POSITIONS + 1)];
    let subset_count = 1usize << (parser.position_count + 1);
    for subset in 1..subset_count {
        let state = subset.trailing_zeros() as usize;
        transitions[subset] = transitions[subset & (subset - 1)] | follow[state];
    }
    let mut byte_masks = [1u16; 128];
    for p in 1..=parser.position_count {
        for byte in 1..128 {
            if parser.symbols[p] == b'.' || parser.symbols[p] as usize == byte {
                byte_masks[byte] |= 1u16 << p;
            }
        }
    }
    let mut staged = [0u8; MAX_TEXT];
    let mut state = 1u16;
    for i in 0..text_len {
        state = transitions[state as usize] & byte_masks[text[i] as usize];
        staged[i] = if state & last[root] != 0 { 1 } else { 0 };
    }
    if text_len != 0 && (output.is_null() || capacity < text_len) { return -2; }
    if text_len != 0 {
        std::slice::from_raw_parts_mut(output, text_len).copy_from_slice(&staged[..text_len]);
    }
    text_len as i64
}
