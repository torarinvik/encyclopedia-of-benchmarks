package bench

MAX_Q :: 32
ARENA :: 64
MIN_KEY :: i64(-15)
MAX_KEY :: i64(15)

Diet_Node :: struct {
	lo: i64,
	hi: i64,
	left: int,
	right: int,
}

new_node :: proc(nodes: ^[ARENA]Diet_Node, used: ^int, lo, hi: i64,
		left, right: int) -> int {
	index := used^
	nodes[index] = Diet_Node{lo = lo, hi = hi, left = left, right = right}
	used^ += 1
	return index
}

pop_max :: proc(nodes: ^[ARENA]Diet_Node, root: int,
		lo: ^i64, hi: ^i64) -> int {
	if nodes[root].right < 0 {
		lo^ = nodes[root].lo
		hi^ = nodes[root].hi
		return nodes[root].left
	}
	nodes[root].right = pop_max(nodes, nodes[root].right, lo, hi)
	return root
}

pop_min :: proc(nodes: ^[ARENA]Diet_Node, root: int,
		lo: ^i64, hi: ^i64) -> int {
	if nodes[root].left < 0 {
		lo^ = nodes[root].lo
		hi^ = nodes[root].hi
		return nodes[root].right
	}
	nodes[root].left = pop_min(nodes, nodes[root].left, lo, hi)
	return root
}

max_interval :: proc(nodes: ^[ARENA]Diet_Node, root_input: int) -> (i64, i64) {
	root := root_input
	for nodes[root].right >= 0 { root = nodes[root].right }
	return nodes[root].lo, nodes[root].hi
}

min_interval :: proc(nodes: ^[ARENA]Diet_Node, root_input: int) -> (i64, i64) {
	root := root_input
	for nodes[root].left >= 0 { root = nodes[root].left }
	return nodes[root].lo, nodes[root].hi
}

insert_node :: proc(nodes: ^[ARENA]Diet_Node, used: ^int, root: int, key: i64,
		interval_count, changed: ^int) -> int {
	if root < 0 {
		interval_count^ += 1
		changed^ = 1
		return new_node(nodes, used, key, key, -1, -1)
	}
	if key < nodes[root].lo {
		if key + 1 == nodes[root].lo {
			nodes[root].lo = key
			changed^ = 1
			if nodes[root].left >= 0 {
				_, pred_hi := max_interval(nodes, nodes[root].left)
				if pred_hi + 1 == key {
					var pred_lo, ignored: i64
					nodes[root].left = pop_max(nodes, nodes[root].left, &pred_lo, &ignored)
					nodes[root].lo = pred_lo
					interval_count^ -= 1
				}
			}
		} else {
			nodes[root].left = insert_node(nodes, used, nodes[root].left, key, interval_count, changed)
		}
		return root
	}
	if key > nodes[root].hi {
		if key == nodes[root].hi + 1 {
			nodes[root].hi = key
			changed^ = 1
			if nodes[root].right >= 0 {
				succ_lo, _ := min_interval(nodes, nodes[root].right)
				if key + 1 == succ_lo {
					var ignored, succ_hi: i64
					nodes[root].right = pop_min(nodes, nodes[root].right, &ignored, &succ_hi)
					nodes[root].hi = succ_hi
					interval_count^ -= 1
				}
			}
		} else {
			nodes[root].right = insert_node(nodes, used, nodes[root].right, key, interval_count, changed)
		}
		return root
	}
	changed^ = 0
	return root
}

erase_node :: proc(nodes: ^[ARENA]Diet_Node, used: ^int, root: int, key: i64,
		interval_count, changed: ^int) -> int {
	if root < 0 { changed^ = 0; return root }
	if key < nodes[root].lo {
		nodes[root].left = erase_node(nodes, used, nodes[root].left, key, interval_count, changed)
		return root
	}
	if key > nodes[root].hi {
		nodes[root].right = erase_node(nodes, used, nodes[root].right, key, interval_count, changed)
		return root
	}
	changed^ = 1
	if nodes[root].lo == nodes[root].hi {
		interval_count^ -= 1
		if nodes[root].left < 0 { return nodes[root].right }
		if nodes[root].right < 0 { return nodes[root].left }
		var pred_lo, pred_hi: i64
		nodes[root].left = pop_max(nodes, nodes[root].left, &pred_lo, &pred_hi)
		nodes[root].lo = pred_lo
		nodes[root].hi = pred_hi
		return root
	}
	if key == nodes[root].lo { nodes[root].lo += 1; return root }
	if key == nodes[root].hi { nodes[root].hi -= 1; return root }
	piece := new_node(nodes, used, key + 1, nodes[root].hi, -1, nodes[root].right)
	nodes[root].hi = key - 1
	nodes[root].right = piece
	interval_count^ += 1
	return root
}

contains_key :: proc(nodes: ^[ARENA]Diet_Node, root_input: int, key: i64) -> bool {
	root := root_input
	for root >= 0 {
		if key < nodes[root].lo { root = nodes[root].left }
		else if key > nodes[root].hi { root = nodes[root].right }
		else { return true }
	}
	return false
}

@(export)
discrete_interval_encoding_tree :: proc "c" (input: [^]i64, length: uint,
		output: [^]u8, capacity: uint) -> i64 {
	if input == nil || length < 1 || length > 2 + 2 * MAX_Q { return -1 }
	q_value := input[0]
	if q_value < 0 || q_value > i64(MAX_Q) { return -1 }
	q := int(q_value)
	if length != uint(1 + 2 * q) { return -1 }
	for op in 0..<q {
		opcode := input[1 + 2 * op]
		key := input[2 + 2 * op]
		if opcode < 0 || opcode > 2 || key < MIN_KEY || key > MAX_KEY { return -1 }
	}
	required := uint(8 * q)
	if (required > 0 && output == nil) || capacity < required { return -2 }

	nodes: [ARENA]Diet_Node
	used, root, cardinality, interval_count := 0, -1, 0, 0
	staged: [MAX_Q]i64
	for op in 0..<q {
		opcode := int(input[1 + 2 * op])
		key := input[2 + 2 * op]
		changed := 0
		if opcode == 0 {
			root = insert_node(&nodes, &used, root, key, &interval_count, &changed)
			if changed != 0 { cardinality += 1 }
		} else if opcode == 1 {
			root = erase_node(&nodes, &used, root, key, &interval_count, &changed)
			if changed != 0 { cardinality -= 1 }
		}
		present := i64(0)
		if contains_key(&nodes, root, key) { present = 1 }
		staged[op] = 64 * i64(cardinality) + 2 * i64(interval_count) + present
	}
	for op in 0..<q {
		word := u64(staged[op])
		for byte in 0..<8 { output[8 * op + byte] = u8((word >> (8 * byte)) & 0xff) }
	}
	return i64(required)
}
