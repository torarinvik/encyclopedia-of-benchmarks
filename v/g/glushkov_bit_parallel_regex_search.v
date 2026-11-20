module glushkov_bit_parallel_regex_search

const max_text = 24
const max_pattern = 32
const max_positions = 8
const max_nodes = 64

struct RegexNode {
	kind     int
	left     int
	right    int
	position int
}

struct RegexParser {
mut:
	pattern        [max_pattern]i64
	length         int
	cursor         int
	node_count     int
	position_count int
	nodes          [max_nodes]RegexNode
	symbols        [max_positions + 1]u8
	failed         bool
}

fn add_node(mut p RegexParser, kind int, left int, right int, position int) int {
	if p.node_count >= max_nodes {
		p.failed = true
		return 0
	}
	result := p.node_count
	p.node_count++
	p.nodes[result] = RegexNode{kind: kind, left: left, right: right, position: position}
	return result
}

fn parse_atom(mut p RegexParser) int {
	if p.cursor >= p.length {
		p.failed = true
		return 0
	}
	token := p.pattern[p.cursor]
	p.cursor++
	if token == 40 {
		result := parse_expression(mut p)
		if p.failed || p.cursor >= p.length || p.pattern[p.cursor] != 41 {
			p.failed = true
			return 0
		}
		p.cursor++
		return result
	}
	if token != 97 && token != 98 && token != 99 && token != 46 {
		p.failed = true
		return 0
	}
	if p.position_count >= max_positions {
		p.failed = true
		return 0
	}
	p.position_count++
	position := p.position_count
	p.symbols[position] = u8(token)
	return add_node(mut p, 1, 0, 0, position)
}

fn parse_repetition(mut p RegexParser) int {
	mut result := parse_atom(mut p)
	if !p.failed && p.cursor < p.length && p.pattern[p.cursor] == 42 {
		p.cursor++
		result = add_node(mut p, 4, result, 0, 0)
	}
	return result
}

fn parse_concatenation(mut p RegexParser) int {
	if p.cursor >= p.length || p.pattern[p.cursor] == 124 || p.pattern[p.cursor] == 41 {
		p.failed = true
		return 0
	}
	mut result := parse_repetition(mut p)
	for !p.failed && p.cursor < p.length && p.pattern[p.cursor] != 124 && p.pattern[p.cursor] != 41 {
		right := parse_repetition(mut p)
		result = add_node(mut p, 2, result, right, 0)
	}
	return result
}

fn parse_expression(mut p RegexParser) int {
	mut result := parse_concatenation(mut p)
	for !p.failed && p.cursor < p.length && p.pattern[p.cursor] == 124 {
		p.cursor++
		right := parse_concatenation(mut p)
		result = add_node(mut p, 3, result, right, 0)
	}
	return result
}

@[export: 'glushkov_bit_parallel_regex_search']
pub fn glushkov_bit_parallel_regex_search(input &i64, length usize, mut output &u8,
	output_capacity usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > 58 { return -1 }
		if input[0] < 0 || input[0] > max_text || input[1] < 1 || input[1] > max_pattern { return -1 }
		text_length := int(input[0])
		pattern_length := int(input[1])
		if length != usize(2 + text_length + pattern_length) { return -1 }
		for i in 0 .. text_length + pattern_length {
			if input[2 + i] < 1 || input[2 + i] > 127 { return -1 }
		}
		mut parser := RegexParser{length: pattern_length}
		for i in 0 .. pattern_length { parser.pattern[i] = input[2 + text_length + i] }
		root := parse_expression(mut parser)
		if parser.failed || parser.cursor != pattern_length || parser.node_count == 0 { return -1 }

		mut nullable := [max_nodes]bool{}
		mut first := [max_nodes]u16{}
		mut last := [max_nodes]u16{}
		mut follow := [max_positions + 1]u16{}
		for i in 0 .. parser.node_count {
			node := parser.nodes[i]
			if node.kind == 1 {
				bit := u16(1) << node.position
				first[i], last[i] = bit, bit
			} else if node.kind == 4 {
				nullable[i] = true
				first[i], last[i] = first[node.left], last[node.left]
				for pos in 1 .. parser.position_count + 1 {
					if (last[node.left] & (u16(1) << pos)) != 0 { follow[pos] |= first[node.left] }
				}
			} else if node.kind == 3 {
				nullable[i] = nullable[node.left] || nullable[node.right]
				first[i] = first[node.left] | first[node.right]
				last[i] = last[node.left] | last[node.right]
			} else {
				nullable[i] = nullable[node.left] && nullable[node.right]
				first[i] = first[node.left]
				if nullable[node.left] { first[i] |= first[node.right] }
				last[i] = last[node.right]
				if nullable[node.right] { last[i] |= last[node.left] }
				for pos in 1 .. parser.position_count + 1 {
					if (last[node.left] & (u16(1) << pos)) != 0 { follow[pos] |= first[node.right] }
				}
			}
		}
		follow[0] = first[root] | 1
		mut transitions := [512]u16{}
		subset_count := 1 << (parser.position_count + 1)
		for subset in 1 .. subset_count {
			mut state := 0
			for ((subset >> state) & 1) == 0 { state++ }
			transitions[subset] = transitions[subset & (subset - 1)] | follow[state]
		}
		mut byte_masks := [128]u16{}
		for i in 0 .. 128 { byte_masks[i] = 1 }
		for pos in 1 .. parser.position_count + 1 {
			for byte in 1 .. 128 {
				if parser.symbols[pos] == `.` || int(parser.symbols[pos]) == byte { byte_masks[byte] |= u16(1) << pos }
			}
		}
		mut staged := [max_text]u8{}
		mut active := u16(1)
		for i in 0 .. text_length {
			active = transitions[int(active)] & byte_masks[int(input[2 + i])]
			if (active & last[root]) != 0 { staged[i] = 1 }
		}
		if text_length > 0 && (output == nil || output_capacity < usize(text_length)) { return -2 }
		for i in 0 .. text_length { output[i] = staged[i] }
		return i64(text_length)
	}
}
