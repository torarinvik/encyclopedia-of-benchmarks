package glushkov_bit_parallel_regex_search

import "core:c"

MAX_TEXT :: 24
MAX_PATTERN :: 32
MAX_POSITIONS :: 8
MAX_NODES :: 64
POSITION_NODE :: 1
CONCAT_NODE :: 2
ALT_NODE :: 3
STAR_NODE :: 4

Regex_Node :: struct { kind, left, right, position: int }
Regex_Parser :: struct {
	pattern: [MAX_PATTERN]i64,
	length, cursor, node_count, position_count: int,
	nodes: [MAX_NODES]Regex_Node,
	symbols: [MAX_POSITIONS + 1]u8,
	failed: bool,
}

add_node :: proc(p: ^Regex_Parser, kind, left, right, position: int) -> int {
	if p.node_count >= MAX_NODES { p.failed = true; return 0 }
	result := p.node_count
	p.node_count += 1
	p.nodes[result] = Regex_Node{kind, left, right, position}
	return result
}

parse_atom :: proc(p: ^Regex_Parser) -> int {
	if p.cursor >= p.length { p.failed = true; return 0 }
	token := p.pattern[p.cursor]
	p.cursor += 1
	if token == 40 {
		result := parse_expression(p)
		if p.failed || p.cursor >= p.length || p.pattern[p.cursor] != 41 { p.failed = true; return 0 }
		p.cursor += 1
		return result
	}
	if token != 97 && token != 98 && token != 99 && token != 46 { p.failed = true; return 0 }
	if p.position_count >= MAX_POSITIONS { p.failed = true; return 0 }
	p.position_count += 1
	position := p.position_count
	p.symbols[position] = u8(token)
	return add_node(p, POSITION_NODE, 0, 0, position)
}

parse_repetition :: proc(p: ^Regex_Parser) -> int {
	result := parse_atom(p)
	if !p.failed && p.cursor < p.length && p.pattern[p.cursor] == 42 {
		p.cursor += 1
		result = add_node(p, STAR_NODE, result, 0, 0)
	}
	return result
}

parse_concatenation :: proc(p: ^Regex_Parser) -> int {
	if p.cursor >= p.length || p.pattern[p.cursor] == 124 || p.pattern[p.cursor] == 41 { p.failed = true; return 0 }
	result := parse_repetition(p)
	for !p.failed && p.cursor < p.length && p.pattern[p.cursor] != 124 && p.pattern[p.cursor] != 41 {
		right := parse_repetition(p)
		result = add_node(p, CONCAT_NODE, result, right, 0)
	}
	return result
}

parse_expression :: proc(p: ^Regex_Parser) -> int {
	result := parse_concatenation(p)
	for !p.failed && p.cursor < p.length && p.pattern[p.cursor] == 124 {
		p.cursor += 1
		right := parse_concatenation(p)
		result = add_node(p, ALT_NODE, result, right, 0)
	}
	return result
}

@(export)
glushkov_bit_parallel_regex_search :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > 58 do return -1
	if input[0] < 0 || input[0] > MAX_TEXT || input[1] < 1 || input[1] > MAX_PATTERN do return -1
	text_length, pattern_length := int(input[0]), int(input[1])
	if length != c.size_t(2 + text_length + pattern_length) do return -1
	for i := 0; i < text_length + pattern_length; i += 1 {
		if input[2+i] < 1 || input[2+i] > 127 do return -1
	}

	var parser: Regex_Parser
	parser.length = pattern_length
	for i := 0; i < pattern_length; i += 1 { parser.pattern[i] = input[2+text_length+i] }
	root := parse_expression(&parser)
	if parser.failed || parser.cursor != pattern_length || parser.node_count == 0 do return -1

	var nullable: [MAX_NODES]bool
	var first, last: [MAX_NODES]u16
	var follow: [MAX_POSITIONS + 1]u16
	for i := 0; i < parser.node_count; i += 1 {
		node := parser.nodes[i]
		if node.kind == POSITION_NODE {
			bit := u16(1) << node.position
			first[i], last[i] = bit, bit
		} else if node.kind == STAR_NODE {
			nullable[i] = true
			first[i], last[i] = first[node.left], last[node.left]
			for pos := 1; pos <= parser.position_count; pos += 1 {
				if (last[node.left] & (u16(1) << pos)) != 0 { follow[pos] |= first[node.left] }
			}
		} else if node.kind == ALT_NODE {
			nullable[i] = nullable[node.left] || nullable[node.right]
			first[i] = first[node.left] | first[node.right]
			last[i] = last[node.left] | last[node.right]
		} else {
			nullable[i] = nullable[node.left] && nullable[node.right]
			first[i] = first[node.left]
			if nullable[node.left] { first[i] |= first[node.right] }
			last[i] = last[node.right]
			if nullable[node.right] { last[i] |= last[node.left] }
			for pos := 1; pos <= parser.position_count; pos += 1 {
				if (last[node.left] & (u16(1) << pos)) != 0 { follow[pos] |= first[node.right] }
			}
		}
	}
	follow[0] = first[root] | 1
	var transitions: [512]u16
	subset_count := 1 << (parser.position_count + 1)
	for subset := 1; subset < subset_count; subset += 1 {
		state := 0
		for ((subset >> state) & 1) == 0 { state += 1 }
		transitions[subset] = transitions[subset&(subset-1)] | follow[state]
	}
	var byte_masks: [128]u16
	for i := 0; i < 128; i += 1 { byte_masks[i] = 1 }
	for pos := 1; pos <= parser.position_count; pos += 1 {
		for b := 1; b < 128; b += 1 {
			if parser.symbols[pos] == '.' || int(parser.symbols[pos]) == b { byte_masks[b] |= u16(1) << pos }
		}
	}
	var staged: [MAX_TEXT]u8
	active := u16(1)
	for i := 0; i < text_length; i += 1 {
		active = transitions[active] & byte_masks[int(input[2+i])]
		if (active & last[root]) != 0 { staged[i] = 1 }
	}
	if text_length > 0 && (output == nil || output_capacity < c.size_t(text_length)) do return -2
	for i := 0; i < text_length; i += 1 { output[i] = staged[i] }
	return i64(text_length)
}
