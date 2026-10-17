const MAX_PATTERN_LENGTH: usize = 16;
const MAX_TEXT_LENGTH: usize = 32;
const MAX_INPUT_LENGTH: usize = 51;
const MAX_AST_NODES: usize = 32;
const MAX_NFA_STATES: usize = 8;
const MAX_NFA_EDGES: usize = 32;

const EPSILON: u8 = 0;
const EMPTY: u8 = 0;
const LITERAL: u8 = 1;
const CONCAT: u8 = 2;
const UNION: u8 = 3;
const STAR: u8 = 4;

#[derive(Clone, Copy, Default)]
struct Node { kind: u8, value: u8, left: usize, right: usize }

struct Parser {
    pattern: [u8; MAX_PATTERN_LENGTH],
    length: usize,
    position: usize,
    nodes: [Node; MAX_AST_NODES],
    node_count: usize,
    fragments: usize,
}

impl Parser {
    fn add_node(&mut self, kind: u8, value: u8, left: usize, right: usize) -> Option<usize> {
        if self.node_count >= MAX_AST_NODES { return None; }
        let index = self.node_count;
        self.nodes[index] = Node { kind, value, left, right };
        self.node_count += 1;
        if kind == LITERAL || kind == UNION || kind == STAR { self.fragments += 1; }
        Some(index)
    }

    fn peek(&self) -> Option<u8> {
        if self.position < self.length { Some(self.pattern[self.position]) } else { None }
    }

    fn parse_union(&mut self) -> Option<usize> {
        let mut node = self.parse_concat()?;
        while self.peek() == Some(b'|') {
            self.position += 1;
            let right = self.parse_concat()?;
            node = self.add_node(UNION, 0, node, right)?;
        }
        Some(node)
    }

    fn parse_concat(&mut self) -> Option<usize> {
        if matches!(self.peek(), None | Some(b')') | Some(b'|')) { return None; }
        let mut node = self.parse_repeat()?;
        while !matches!(self.peek(), None | Some(b')') | Some(b'|')) {
            let right = self.parse_repeat()?;
            node = self.add_node(CONCAT, 0, node, right)?;
        }
        Some(node)
    }

    fn parse_repeat(&mut self) -> Option<usize> {
        let mut node = self.parse_atom()?;
        if self.peek() == Some(b'*') {
            self.position += 1;
            node = self.add_node(STAR, 0, node, 0)?;
        }
        Some(node)
    }

    fn parse_atom(&mut self) -> Option<usize> {
        match self.peek()? {
            b'a' | b'b' | b'c' => {
                let value = self.peek()?;
                self.position += 1;
                self.add_node(LITERAL, value, 0, 0)
            }
            b'(' => {
                self.position += 1;
                let node = self.parse_union()?;
                if self.peek() != Some(b')') { return None; }
                self.position += 1;
                Some(node)
            }
            _ => None,
        }
    }
}

fn source_parser_compatible(pattern: &[u8]) -> bool {
    let mut preprocessed = [0_u8; 2 * MAX_PATTERN_LENGTH];
    let mut length = 0;
    for index in 0..pattern.len() {
        let token = pattern[index];
        preprocessed[length] = token;
        length += 1;
        if index + 1 == pattern.len() { continue; }
        let next = pattern[index + 1];
        let token_literal = !matches!(token, b'(' | b')' | b'*' | b'|' | b'\n');
        let next_literal = !matches!(next, b'(' | b')' | b'*' | b'|' | b'\n');
        if (token_literal && next_literal)
            || (token_literal && next == b'(')
            || (token == b')' && next == b'(')
            || (token == b')' && next_literal)
            || (token == b'*' && next_literal)
            || (token == b'*' && next == b'(')
        {
            preprocessed[length] = b'\n';
            length += 1;
        }
    }

    fn compatible(source: &[u8]) -> bool {
        if source.len() <= 1 { return true; }
        if source[0] == b'(' && source[source.len() - 1] == b')' {
            let mut depth = 0_i32;
            for (index, token) in source.iter().enumerate() {
                if *token == b'(' { depth += 1; }
                if *token == b')' { depth -= 1; }
                if depth == 0 && index + 1 < source.len() { return false; }
            }
            if depth != 0 { return false; }
            return compatible(&source[1..source.len() - 1]);
        }
        for operator in [b'|', b'\n'] {
            let mut depth = 0_i32;
            for (index, token) in source.iter().enumerate() {
                if depth == 0 && *token == operator {
                    return compatible(&source[..index]) && compatible(&source[index + 1..]);
                }
                if *token == b'(' { depth += 1; }
                if *token == b')' { depth -= 1; }
            }
        }
        source.last() == Some(&b'*') && compatible(&source[..source.len() - 1])
    }

    compatible(&preprocessed[..length])
}

#[derive(Clone, Copy, Default)]
struct Edge { from: u8, to: u8, label: u8 }

struct Nfa { state_count: usize, edge_count: usize, edges: [Edge; MAX_NFA_EDGES] }
#[derive(Clone, Copy)]
struct Fragment { start: usize, accept: usize }

impl Nfa {
    fn state(&mut self) -> Option<usize> {
        if self.state_count >= MAX_NFA_STATES { return None; }
        let state = self.state_count;
        self.state_count += 1;
        Some(state)
    }
    fn edge(&mut self, from: usize, to: usize, label: u8) -> bool {
        if self.edge_count >= MAX_NFA_EDGES { return false; }
        self.edges[self.edge_count] = Edge { from: from as u8, to: to as u8, label };
        self.edge_count += 1;
        true
    }
}

fn compile(node_index: usize, nodes: &[Node], nfa: &mut Nfa) -> Option<Fragment> {
    let node = nodes[node_index];
    match node.kind {
        EMPTY => {
            let start = nfa.state()?;
            let accept = nfa.state()?;
            if !nfa.edge(start, accept, EPSILON) { return None; }
            Some(Fragment { start, accept })
        }
        LITERAL => {
            let start = nfa.state()?;
            let accept = nfa.state()?;
            if !nfa.edge(start, accept, node.value) { return None; }
            Some(Fragment { start, accept })
        }
        CONCAT => {
            let left = compile(node.left, nodes, nfa)?;
            let right = compile(node.right, nodes, nfa)?;
            if !nfa.edge(left.accept, right.start, EPSILON) { return None; }
            Some(Fragment { start: left.start, accept: right.accept })
        }
        UNION => {
            let left = compile(node.left, nodes, nfa)?;
            let right = compile(node.right, nodes, nfa)?;
            let start = nfa.state()?;
            let accept = nfa.state()?;
            if !nfa.edge(start, left.start, EPSILON)
                || !nfa.edge(start, right.start, EPSILON)
                || !nfa.edge(left.accept, accept, EPSILON)
                || !nfa.edge(right.accept, accept, EPSILON)
            { return None; }
            Some(Fragment { start, accept })
        }
        STAR => {
            let child = compile(node.left, nodes, nfa)?;
            let start = nfa.state()?;
            let accept = nfa.state()?;
            if !nfa.edge(start, child.start, EPSILON)
                || !nfa.edge(start, accept, EPSILON)
                || !nfa.edge(child.accept, child.start, EPSILON)
                || !nfa.edge(child.accept, accept, EPSILON)
            { return None; }
            Some(Fragment { start, accept })
        }
        _ => None,
    }
}

fn epsilon_closure(mut states: u16, nfa: &Nfa) -> u16 {
    loop {
        let before = states;
        for edge in nfa.edges.iter().take(nfa.edge_count) {
            if edge.label == EPSILON && (states & (1 << edge.from)) != 0 {
                states |= 1 << edge.to;
            }
        }
        if states == before { return states; }
    }
}

#[no_mangle]
pub unsafe extern "C" fn mcnaughton_yamada_thompson(input: *const i64, input_length: usize) -> i64 {
    if input.is_null() || input_length < 2 || input_length > MAX_INPUT_LENGTH { return -1; }
    let values = unsafe { std::slice::from_raw_parts(input, input_length) };
    let pattern_length = values[0];
    let text_length = values[1];
    if !(0..=MAX_PATTERN_LENGTH as i64).contains(&pattern_length)
        || !(0..=MAX_TEXT_LENGTH as i64).contains(&text_length)
        || input_length != 2 + pattern_length as usize + text_length as usize
    { return -1; }

    let pattern_start = 2;
    let text_start = pattern_start + pattern_length as usize;
    let mut pattern = [0_u8; MAX_PATTERN_LENGTH];
    for index in 0..pattern_length as usize {
        let value = values[pattern_start + index];
        if !matches!(value, 97 | 98 | 99 | 40 | 41 | 42 | 124) { return -1; }
        pattern[index] = value as u8;
    }
    for index in 0..text_length as usize {
        let value = values[text_start + index];
        if !(1..=127).contains(&value) { return -1; }
    }
    if !source_parser_compatible(&pattern[..pattern_length as usize]) { return -1; }

    let mut parser = Parser {
        pattern, length: pattern_length as usize, position: 0,
        nodes: [Node::default(); MAX_AST_NODES], node_count: 0, fragments: 0,
    };
    let root = if parser.length == 0 {
        parser.add_node(EMPTY, 0, 0, 0)
    } else {
        parser.parse_union()
    };
    let Some(root) = root else { return -1; };
    if parser.position != parser.length || parser.fragments > 4 { return -1; }

    let mut nfa = Nfa { state_count: 0, edge_count: 0, edges: [Edge::default(); MAX_NFA_EDGES] };
    let Some(fragment) = compile(root, &parser.nodes, &mut nfa) else { return -1; };
    let mut active = epsilon_closure(1 << fragment.start, &nfa);
    for index in 0..text_length as usize {
        let symbol = values[text_start + index] as u8;
        let mut next = 0_u16;
        for edge in nfa.edges.iter().take(nfa.edge_count) {
            if edge.label == symbol && (active & (1 << edge.from)) != 0 {
                next |= 1 << edge.to;
            }
        }
        active = epsilon_closure(next, &nfa);
    }
    if active & (1 << fragment.accept) != 0 { 1 } else { 0 }
}
