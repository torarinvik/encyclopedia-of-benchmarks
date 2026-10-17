module mcnaughton_yamada_thompson

const max_pattern_length = 16
const max_text_length = 32
const max_input_length = 51
const max_ast_nodes = 32
const max_nfa_states = 8
const max_nfa_edges = 32

const empty_kind = 0
const literal_kind = 1
const concat_kind = 2
const union_kind = 3
const star_kind = 4

struct Node {
mut:
	kind int
	value u8
	left int
	right int
}

struct Parser {
mut:
	pattern [max_pattern_length]u8
	length int
	position int
	nodes [max_ast_nodes]Node
	node_count int
	fragments int
}

fn (mut parser Parser) add_node(kind int, value u8, left int, right int) int {
	if parser.node_count >= max_ast_nodes { return -1 }
	index := parser.node_count
	parser.nodes[index] = Node{kind: kind, value: value, left: left, right: right}
	parser.node_count++
	if kind == literal_kind || kind == union_kind || kind == star_kind { parser.fragments++ }
	return index
}

fn (parser &Parser) peek() int {
	if parser.position < parser.length { return int(parser.pattern[parser.position]) }
	return -1
}

fn parse_union(mut parser Parser) int {
	mut node := parse_concat(mut parser)
	if node < 0 { return -1 }
	for parser.peek() == `|` {
		parser.position++
		right := parse_concat(mut parser)
		if right < 0 { return -1 }
		node = parser.add_node(union_kind, 0, node, right)
		if node < 0 { return -1 }
	}
	return node
}

fn parse_concat(mut parser Parser) int {
	if parser.peek() < 0 || parser.peek() == `)` || parser.peek() == `|` { return -1 }
	mut node := parse_repeat(mut parser)
	if node < 0 { return -1 }
	for parser.peek() >= 0 && parser.peek() != `)` && parser.peek() != `|` {
		right := parse_repeat(mut parser)
		if right < 0 { return -1 }
		node = parser.add_node(concat_kind, 0, node, right)
		if node < 0 { return -1 }
	}
	return node
}

fn parse_repeat(mut parser Parser) int {
	mut node := parse_atom(mut parser)
	if node < 0 { return -1 }
	if parser.peek() == `*` {
		parser.position++
		node = parser.add_node(star_kind, 0, node, 0)
	}
	return node
}

fn parse_atom(mut parser Parser) int {
	token := parser.peek()
	if token == `a` || token == `b` || token == `c` {
		parser.position++
		return parser.add_node(literal_kind, u8(token), 0, 0)
	}
	if token == `(` {
		parser.position++
		node := parse_union(mut parser)
		if node < 0 || parser.peek() != `)` { return -1 }
		parser.position++
		return node
	}
	return -1
}

fn is_literal(token u8) bool {
	return token != `(` && token != `)` && token != `*` && token != `|` && token != `\n`
}

fn source_substring_compatible(source []u8) bool {
	if source.len <= 1 { return true }
	if source[0] == `(` && source[source.len - 1] == `)` {
		mut depth := 0
		for index, token in source {
			if token == `(` { depth++ }
			if token == `)` { depth-- }
			if depth == 0 && index + 1 < source.len { return false }
		}
		if depth != 0 { return false }
		return source_substring_compatible(source[1..source.len - 1])
	}
	for operator in [`|`, `\n`] {
		mut depth := 0
		for index, token in source {
			if depth == 0 && token == operator {
				return source_substring_compatible(source[..index]) &&
					source_substring_compatible(source[index + 1..])
			}
			if token == `(` { depth++ }
			if token == `)` { depth-- }
		}
	}
	return source[source.len - 1] == `*` && source_substring_compatible(source[..source.len - 1])
}

fn source_compatible(pattern []u8) bool {
	mut preprocessed := []u8{cap: 2 * max_pattern_length}
	for index, token in pattern {
		preprocessed << token
		if index + 1 == pattern.len { continue }
		next := pattern[index + 1]
		if (is_literal(token) && is_literal(next)) || (is_literal(token) && next == `(`)
			|| (token == `)` && next == `(`) || (token == `)` && is_literal(next))
			|| (token == `*` && is_literal(next)) || (token == `*` && next == `(`) {
			preprocessed << `\n`
		}
	}
	return source_substring_compatible(preprocessed)
}

struct Edge {
	from int
	to int
	label u8
}

struct Nfa {
mut:
	state_count int
	edge_count int
	edges [max_nfa_edges]Edge
}

struct Fragment {
	start int
	accept int
}

fn (mut nfa Nfa) add_state() int {
	if nfa.state_count >= max_nfa_states { return -1 }
	state := nfa.state_count
	nfa.state_count++
	return state
}

fn (mut nfa Nfa) add_edge(from int, to int, label u8) bool {
	if nfa.edge_count >= max_nfa_edges { return false }
	nfa.edges[nfa.edge_count] = Edge{from: from, to: to, label: label}
	nfa.edge_count++
	return true
}

fn compile(node_index int, nodes &Node, mut nfa Nfa) Fragment {
	node := nodes[node_index]
	match node.kind {
		empty_kind {
			start := nfa.add_state()
			accept := nfa.add_state()
			if start < 0 || accept < 0 || !nfa.add_edge(start, accept, 0) { return Fragment{-1, -1} }
			return Fragment{start, accept}
		}
		literal_kind {
			start := nfa.add_state()
			accept := nfa.add_state()
			if start < 0 || accept < 0 || !nfa.add_edge(start, accept, node.value) { return Fragment{-1, -1} }
			return Fragment{start, accept}
		}
		concat_kind {
			left := compile(node.left, nodes, mut nfa)
			if left.start < 0 { return left }
			right := compile(node.right, nodes, mut nfa)
			if right.start < 0 || !nfa.add_edge(left.accept, right.start, 0) { return Fragment{-1, -1} }
			return Fragment{left.start, right.accept}
		}
		union_kind {
			left := compile(node.left, nodes, mut nfa)
			if left.start < 0 { return left }
			right := compile(node.right, nodes, mut nfa)
			if right.start < 0 { return right }
			start := nfa.add_state()
			accept := nfa.add_state()
			if start < 0 || accept < 0 || !nfa.add_edge(start, left.start, 0)
				|| !nfa.add_edge(start, right.start, 0) || !nfa.add_edge(left.accept, accept, 0)
				|| !nfa.add_edge(right.accept, accept, 0) { return Fragment{-1, -1} }
			return Fragment{start, accept}
		}
		star_kind {
			child := compile(node.left, nodes, mut nfa)
			if child.start < 0 { return child }
			start := nfa.add_state()
			accept := nfa.add_state()
			if start < 0 || accept < 0 || !nfa.add_edge(start, child.start, 0)
				|| !nfa.add_edge(start, accept, 0) || !nfa.add_edge(child.accept, child.start, 0)
				|| !nfa.add_edge(child.accept, accept, 0) { return Fragment{-1, -1} }
			return Fragment{start, accept}
		}
		else { return Fragment{-1, -1} }
	}
}

fn epsilon_closure(mut states u32, nfa &Nfa) u32 {
	for {
		before := states
		for index in 0 .. nfa.edge_count {
			edge := nfa.edges[index]
			if edge.label == 0 && (states & (u32(1) << edge.from)) != 0 {
				states |= u32(1) << edge.to
			}
		}
		if states == before { return states }
	}
}

@[export: 'mcnaughton_yamada_thompson']
pub fn mcnaughton_yamada_thompson(input &i64, input_length usize) i64 {
	unsafe {
		if input == nil || input_length < 2 || input_length > max_input_length { return -1 }
		if input[0] < 0 || input[0] > max_pattern_length || input[1] < 0 || input[1] > max_text_length { return -1 }
		pattern_length := int(input[0])
		text_length := int(input[1])
		if input_length != usize(2 + pattern_length + text_length) { return -1 }
		mut pattern := []u8{cap: max_pattern_length}
		for index in 0 .. pattern_length {
			value := input[2 + index]
			if value != 97 && value != 98 && value != 99 && value != 40 && value != 41 && value != 42 && value != 124 { return -1 }
			pattern << u8(value)
		}
		text_start := 2 + pattern_length
		for index in 0 .. text_length {
			if input[text_start + index] < 1 || input[text_start + index] > 127 { return -1 }
		}
		if !source_compatible(pattern) { return -1 }

		mut parser := Parser{pattern: [max_pattern_length]u8{}, length: pattern_length}
		for index, value in pattern { parser.pattern[index] = value }
		root := if pattern_length == 0 { parser.add_node(empty_kind, 0, 0, 0) } else { parse_union(mut parser) }
		if root < 0 || parser.position != parser.length || parser.fragments > 4 { return -1 }

		mut nfa := Nfa{}
		fragment := compile(root, &parser.nodes[0], mut nfa)
		if fragment.start < 0 { return -1 }
		mut active := epsilon_closure(u32(1) << fragment.start, &nfa)
		for index in 0 .. text_length {
			symbol := u8(input[text_start + index])
			mut next := u32(0)
			for edge_index in 0 .. nfa.edge_count {
				edge := nfa.edges[edge_index]
				if edge.label == symbol && (active & (u32(1) << edge.from)) != 0 { next |= u32(1) << edge.to }
			}
			active = epsilon_closure(next, &nfa)
		}
		if (active & (u32(1) << fragment.accept)) != 0 { return 1 }
		return 0
	}
}
