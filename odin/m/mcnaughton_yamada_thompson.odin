package mcnaughton_yamada_thompson

import "core:c"

MAX_PATTERN :: 16
MAX_TEXT :: 32
MAX_INPUT :: c.size_t(51)
MAX_NODES :: 32
MAX_STATES :: 8
MAX_EDGES :: 32
EMPTY :: 0
LITERAL :: 1
CONCAT :: 2
UNION :: 3
STAR :: 4

Node :: struct { kind: u8, value: u8, left, right: int }
Parser :: struct {
	pattern: [MAX_PATTERN]u8,
	length, position, node_count, fragments: int,
	nodes: [MAX_NODES]Node,
}
Edge :: struct { from, to: int, label: u8 }
NFA :: struct { state_count, edge_count: int, edges: [MAX_EDGES]Edge }
Fragment :: struct { start, accept: int, valid: bool }

add_node :: proc(parser: ^Parser, kind, value: u8, left, right: int) -> int {
	if parser.node_count >= MAX_NODES do return -1
	index := parser.node_count
	parser.nodes[index] = Node{kind, value, left, right}
	parser.node_count += 1
	if kind == LITERAL || kind == UNION || kind == STAR do parser.fragments += 1
	return index
}

peek :: proc(parser: ^Parser) -> int {
	if parser.position < parser.length do return int(parser.pattern[parser.position])
	return -1
}

parse_union :: proc(parser: ^Parser) -> int {
	left := parse_concat(parser)
	if left < 0 do return -1
	for peek(parser) == int('|') {
		parser.position += 1
		right := parse_concat(parser)
		if right < 0 do return -1
		left = add_node(parser, UNION, 0, left, right)
		if left < 0 do return -1
	}
	return left
}

parse_concat :: proc(parser: ^Parser) -> int {
	if peek(parser) < 0 || peek(parser) == int(')') || peek(parser) == int('|') do return -1
	left := parse_repeat(parser)
	if left < 0 do return -1
	for peek(parser) >= 0 && peek(parser) != int(')') && peek(parser) != int('|') {
		right := parse_repeat(parser)
		if right < 0 do return -1
		left = add_node(parser, CONCAT, 0, left, right)
		if left < 0 do return -1
	}
	return left
}

parse_repeat :: proc(parser: ^Parser) -> int {
	node := parse_atom(parser)
	if node < 0 do return -1
	if peek(parser) == int('*') {
		parser.position += 1
		node = add_node(parser, STAR, 0, node, 0)
	}
	return node
}

parse_atom :: proc(parser: ^Parser) -> int {
	token := peek(parser)
	if token == int('a') || token == int('b') || token == int('c') {
		parser.position += 1
		return add_node(parser, LITERAL, u8(token), 0, 0)
	}
	if token == int('(') {
		parser.position += 1
		node := parse_union(parser)
		if node < 0 || peek(parser) != int(')') do return -1
		parser.position += 1
		return node
	}
	return -1
}

source_compatible :: proc(source: ^[MAX_PATTERN*2]u8, start, length: int) -> bool {
	if length <= 1 do return true
	if source[start] == u8('(') && source[start + length - 1] == u8(')') {
		depth := 0
		for index := 0; index < length; index += 1 {
			token := source[start + index]
			if token == u8('(') do depth += 1 else if token == u8(')') do depth -= 1
			if depth == 0 && index + 1 < length do return false
		}
		if depth != 0 do return false
		return source_compatible(source, start + 1, length - 2)
	}
	for operator_index := 0; operator_index < 2; operator_index += 1 {
		operator := u8('|')
		if operator_index == 1 do operator = 10
		depth := 0
		for index := 0; index < length; index += 1 {
			token := source[start + index]
			if depth == 0 && token == operator {
				return source_compatible(source, start, index) &&
					source_compatible(source, start + index + 1, length - index - 1)
			}
			if token == u8('(') do depth += 1 else if token == u8(')') do depth -= 1
		}
	}
	if source[start + length - 1] == u8('*') do return source_compatible(source, start, length - 1)
	return true
}

new_state :: proc(nfa: ^NFA) -> int {
	if nfa.state_count >= MAX_STATES do return -1
	state := nfa.state_count
	nfa.state_count += 1
	return state
}

add_edge :: proc(nfa: ^NFA, from, to: int, label: u8) -> bool {
	if nfa.edge_count >= MAX_EDGES do return false
	nfa.edges[nfa.edge_count] = Edge{from, to, label}
	nfa.edge_count += 1
	return true
}

compile_node :: proc(node_index: int, nodes: ^[MAX_NODES]Node, nfa: ^NFA) -> Fragment {
	node := nodes[node_index]
	if node.kind == EMPTY || node.kind == LITERAL {
		start := new_state(nfa)
		accept := new_state(nfa)
		if start < 0 || accept < 0 do return Fragment{0, 0, false}
		label := node.value
		if node.kind == EMPTY do label = 0
		if !add_edge(nfa, start, accept, label) do return Fragment{0, 0, false}
		return Fragment{start, accept, true}
	}
	if node.kind == CONCAT {
		left := compile_node(node.left, nodes, nfa)
		if !left.valid do return left
		right := compile_node(node.right, nodes, nfa)
		if !right.valid || !add_edge(nfa, left.accept, right.start, 0) do return Fragment{0, 0, false}
		return Fragment{left.start, right.accept, true}
	}
	if node.kind == UNION {
		left := compile_node(node.left, nodes, nfa)
		if !left.valid do return left
		right := compile_node(node.right, nodes, nfa)
		if !right.valid do return right
		start := new_state(nfa)
		accept := new_state(nfa)
		if start < 0 || accept < 0 do return Fragment{0, 0, false}
		if !add_edge(nfa, start, left.start, 0) || !add_edge(nfa, start, right.start, 0) ||
			!add_edge(nfa, left.accept, accept, 0) || !add_edge(nfa, right.accept, accept, 0) do return Fragment{0, 0, false}
		return Fragment{start, accept, true}
	}
	child := compile_node(node.left, nodes, nfa)
	if !child.valid do return child
	start := new_state(nfa)
	accept := new_state(nfa)
	if start < 0 || accept < 0 do return Fragment{0, 0, false}
	if !add_edge(nfa, start, child.start, 0) || !add_edge(nfa, start, accept, 0) ||
		!add_edge(nfa, child.accept, child.start, 0) || !add_edge(nfa, child.accept, accept, 0) do return Fragment{0, 0, false}
	return Fragment{start, accept, true}
}

epsilon_closure :: proc(states: u16, nfa: ^NFA) -> u16 {
	active := states
	changed := true
	for changed {
		changed = false
		for index := 0; index < nfa.edge_count; index += 1 {
			edge := nfa.edges[index]
			if edge.label == 0 && (active & (u16(1) << u16(edge.from))) != 0 {
				mask := u16(1) << u16(edge.to)
				if active & mask == 0 { active |= mask; changed = true }
			}
		}
	}
	return active
}

@(export)
mcnaughton_yamada_thompson :: proc "c" (input: [^]i64, input_length: c.size_t) -> i64 {
	if input == nil || input_length < 2 || input_length > MAX_INPUT do return -1
	pattern_length_value := input[0]
	text_length_value := input[1]
	if pattern_length_value < 0 || pattern_length_value > MAX_PATTERN ||
		text_length_value < 0 || text_length_value > MAX_TEXT do return -1
	pattern_length := int(pattern_length_value)
	text_length := int(text_length_value)
	if int(input_length) != 2 + pattern_length + text_length do return -1

	pattern: [MAX_PATTERN]u8
	for index := 0; index < pattern_length; index += 1 {
		value := input[2 + index]
		if value != 97 && value != 98 && value != 99 && value != 40 && value != 41 && value != 42 && value != 124 do return -1
		pattern[index] = u8(value)
	}
	for index := 0; index < text_length; index += 1 {
		value := input[2 + pattern_length + index]
		if value < 1 || value > 127 do return -1
	}

	preprocessed: [MAX_PATTERN*2]u8
	processed_length := 0
	for index := 0; index < pattern_length; index += 1 {
		token := pattern[index]
		preprocessed[processed_length] = token
		processed_length += 1
		if index + 1 >= pattern_length do continue
		following := pattern[index + 1]
		token_literal := token != u8('(') && token != u8(')') && token != u8('*') && token != u8('|')
		next_literal := following != u8('(') && following != u8(')') && following != u8('*') && following != u8('|')
		if (token_literal && next_literal) || (token_literal && following == u8('(')) ||
			(token == u8(')') && following == u8('(')) || (token == u8(')') && next_literal) ||
			(token == u8('*') && next_literal) || (token == u8('*') && following == u8('(')) {
			preprocessed[processed_length] = 10
			processed_length += 1
		}
	}
	if pattern_length > 0 && !source_compatible(&preprocessed, 0, processed_length) do return -1

	parser := Parser{pattern = pattern, length = pattern_length}
	root := -1
	if pattern_length == 0 {
		root = add_node(&parser, EMPTY, 0, 0, 0)
	} else {
		root = parse_union(&parser)
	}
	if root < 0 || parser.position != pattern_length || parser.fragments > 4 do return -1

	nfa: NFA
	fragment := compile_node(root, &parser.nodes, &nfa)
	if !fragment.valid do return -1
	active := epsilon_closure(u16(1) << u16(fragment.start), &nfa)
	for index := 0; index < text_length; index += 1 {
		symbol := u8(input[2 + pattern_length + index])
		next: u16 = 0
		for edge_index := 0; edge_index < nfa.edge_count; edge_index += 1 {
			edge := nfa.edges[edge_index]
			if edge.label == symbol && (active & (u16(1) << u16(edge.from))) != 0 {
				next |= u16(1) << u16(edge.to)
			}
		}
		active = epsilon_closure(next, &nfa)
	}
	if (active & (u16(1) << u16(fragment.accept))) != 0 do return 1
	return 0
}
