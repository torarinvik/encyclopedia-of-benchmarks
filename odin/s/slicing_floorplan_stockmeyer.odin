package slicing_floorplan_stockmeyer

import "core:c"

MAX_LEAVES :: 8
MAX_NODES :: 15
MAX_CANDIDATES :: 256
MAX_INPUT :: 32
OUTPUT_BYTES :: 32

Candidate :: struct { height, width: i64, mask: u64 }
Node :: struct {
	op, left, right: int,
	cell_height, cell_width: i64,
	leaf_index, count: int,
	candidates: [MAX_CANDIDATES]Candidate,
}

mask_lex_less :: proc(a, b: u64, leaves: int) -> bool {
	for bit := 0; bit < leaves; bit += 1 {
		av, bv := (a >> u64(bit)) & 1, (b >> u64(bit)) & 1
		if av != bv do return av < bv
	}
	return false
}

prune :: proc(node: ^Node, leaves: int) {
	var dominated: [MAX_CANDIDATES]bool
	for i := 0; i < node.count; i += 1 {
		a := node.candidates[i]
		for j := 0; j < node.count; j += 1 {
			if i == j do continue
			b := node.candidates[j]
			if b.height <= a.height && b.width <= a.width &&
				(b.height < a.height || b.width < a.width || mask_lex_less(b.mask, a.mask, leaves) || (b.mask == a.mask && j < i)) {
				dominated[i] = true
				break
			}
		}
	}
	kept := 0
	for i := 0; i < node.count; i += 1 {
		if !dominated[i] { node.candidates[kept] = node.candidates[i]; kept += 1 }
	}
	node.count = kept
}

store_i64_le :: proc(output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 {
		output[offset+byte] = u8(bits & 255)
		bits >>= 8
	}
}

@(export)
slicing_floorplan_stockmeyer :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 4 || length > MAX_INPUT || input[0] < 1 || input[0] > MAX_LEAVES do return -1
	leaves := int(input[0])
	var nodes: [MAX_NODES]Node
	var stack: [MAX_NODES]int
	stack_size, node_count, leaf_count, internal_count := 0, 0, 0, 0
	position := 1
	for position < int(length) {
		token := input[position]
		position += 1
		if token == 2 {
			if position+2 > int(length) || leaf_count >= leaves || node_count >= MAX_NODES do return -1
			height, width := input[position], input[position+1]
			position += 2
			if height < 1 || height > 20 || width < 1 || width > 20 do return -1
			node := &nodes[node_count]
			node.op, node.cell_height, node.cell_width, node.leaf_index = 2, height, width, leaf_count
			node.candidates[0] = {height, width, 0}
			node.candidates[1] = {width, height, u64(1) << u64(leaf_count)}
			node.count = 2
			prune(node, leaves)
			stack[stack_size] = node_count
			stack_size += 1
			node_count += 1
			leaf_count += 1
		} else if token == 0 || token == 1 {
			if stack_size < 2 || internal_count >= leaves-1 || node_count >= MAX_NODES do return -1
			stack_size -= 1
			rnode := stack[stack_size]
			stack_size -= 1
			lnode := stack[stack_size]
			if nodes[rnode].op == int(token) do return -1
			node := &nodes[node_count]
			node.op, node.left, node.right = int(token), lnode, rnode
			for i := 0; i < nodes[lnode].count; i += 1 {
				for j := 0; j < nodes[rnode].count; j += 1 {
					if node.count >= MAX_CANDIDATES do return -1
					a, b := nodes[lnode].candidates[i], nodes[rnode].candidates[j]
					cnd := Candidate{mask = a.mask | b.mask}
					if token == 0 {
						cnd.height = max(a.height, b.height)
						cnd.width = a.width + b.width
					} else {
						cnd.height = a.height + b.height
						cnd.width = max(a.width, b.width)
					}
					node.candidates[node.count] = cnd
					node.count += 1
				}
			}
			prune(node, leaves)
			stack[stack_size] = node_count
			stack_size += 1
			node_count += 1
			internal_count += 1
		} else { return -1 }
	}
	if position != int(length) || leaf_count != leaves || internal_count != leaves-1 || node_count != 2*leaves-1 || stack_size != 1 do return -1
	root := nodes[stack[0]]
	if root.count == 0 do return -1
	best := root.candidates[0]
	for i := 1; i < root.count; i += 1 {
		candidate := root.candidates[i]
		area, best_area := candidate.height*candidate.width, best.height*best.width
		if area < best_area || (area == best_area && (candidate.height < best.height ||
			(candidate.height == best.height && (candidate.width < best.width ||
			(candidate.width == best.width && mask_lex_less(candidate.mask, best.mask, leaves))))) do best = candidate
	}
	if output == nil || capacity < OUTPUT_BYTES do return -2
	var staged: [OUTPUT_BYTES]u8
	store_i64_le(&staged[0], 0, best.height*best.width)
	store_i64_le(&staged[0], 8, best.height)
	store_i64_le(&staged[0], 16, best.width)
	store_i64_le(&staged[0], 24, i64(best.mask))
	for byte := 0; byte < OUTPUT_BYTES; byte += 1 do output[byte] = staged[byte]
	return OUTPUT_BYTES
}
