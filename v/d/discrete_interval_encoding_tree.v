const diet_max_q = 32
const diet_arena = 64
const diet_min_key = i64(-15)
const diet_max_key = i64(15)

struct DietNode {
	lo i64
	hi i64
	left int
	right int
}

fn diet_new(mut nodes []DietNode, mut used int, lo i64, hi i64, left int, right int) int {
	index := used
	used++
	nodes[index] = DietNode{lo: lo, hi: hi, left: left, right: right}
	return index
}

fn diet_pop_max(mut nodes []DietNode, root int, mut lo i64, mut hi i64) int {
	if nodes[root].right < 0 {
		lo = nodes[root].lo
		hi = nodes[root].hi
		return nodes[root].left
	}
	nodes[root].right = diet_pop_max(mut nodes, nodes[root].right, mut lo, mut hi)
	return root
}

fn diet_pop_min(mut nodes []DietNode, root int, mut lo i64, mut hi i64) int {
	if nodes[root].left < 0 {
		lo = nodes[root].lo
		hi = nodes[root].hi
		return nodes[root].right
	}
	nodes[root].left = diet_pop_min(mut nodes, nodes[root].left, mut lo, mut hi)
	return root
}

fn diet_max_interval(nodes []DietNode, root_input int) (i64, i64) {
	mut root := root_input
	for nodes[root].right >= 0 {
		root = nodes[root].right
	}
	return nodes[root].lo, nodes[root].hi
}

fn diet_min_interval(nodes []DietNode, root_input int) (i64, i64) {
	mut root := root_input
	for nodes[root].left >= 0 {
		root = nodes[root].left
	}
	return nodes[root].lo, nodes[root].hi
}

fn diet_insert(mut nodes []DietNode, mut used int, root int, key i64,
	mut interval_count int, mut changed bool) int {
	if root < 0 {
		interval_count++
		changed = true
		return diet_new(mut nodes, mut used, key, key, -1, -1)
	}
	if key < nodes[root].lo {
		if key + 1 == nodes[root].lo {
			nodes[root].lo = key
			changed = true
			if nodes[root].left >= 0 {
				_, pred_hi := diet_max_interval(nodes, nodes[root].left)
				if pred_hi + 1 == key {
					mut pred_lo := i64(0)
					mut ignored := i64(0)
					nodes[root].left = diet_pop_max(mut nodes, nodes[root].left, mut pred_lo, mut ignored)
					nodes[root].lo = pred_lo
					interval_count--
				}
			}
		} else {
			nodes[root].left = diet_insert(mut nodes, mut used, nodes[root].left, key,
				mut interval_count, mut changed)
		}
		return root
	}
	if key > nodes[root].hi {
		if key == nodes[root].hi + 1 {
			nodes[root].hi = key
			changed = true
			if nodes[root].right >= 0 {
				succ_lo, _ := diet_min_interval(nodes, nodes[root].right)
				if key + 1 == succ_lo {
					mut ignored := i64(0)
					mut succ_hi := i64(0)
					nodes[root].right = diet_pop_min(mut nodes, nodes[root].right, mut ignored, mut succ_hi)
					nodes[root].hi = succ_hi
					interval_count--
				}
			}
		} else {
			nodes[root].right = diet_insert(mut nodes, mut used, nodes[root].right, key,
				mut interval_count, mut changed)
		}
		return root
	}
	changed = false
	return root
}

fn diet_erase(mut nodes []DietNode, mut used int, root int, key i64,
	mut interval_count int, mut changed bool) int {
	if root < 0 {
		changed = false
		return root
	}
	if key < nodes[root].lo {
		nodes[root].left = diet_erase(mut nodes, mut used, nodes[root].left, key,
			mut interval_count, mut changed)
		return root
	}
	if key > nodes[root].hi {
		nodes[root].right = diet_erase(mut nodes, mut used, nodes[root].right, key,
			mut interval_count, mut changed)
		return root
	}
	changed = true
	if nodes[root].lo == nodes[root].hi {
		interval_count--
		if nodes[root].left < 0 { return nodes[root].right }
		if nodes[root].right < 0 { return nodes[root].left }
		mut pred_lo := i64(0)
		mut pred_hi := i64(0)
		nodes[root].left = diet_pop_max(mut nodes, nodes[root].left, mut pred_lo, mut pred_hi)
		nodes[root].lo = pred_lo
		nodes[root].hi = pred_hi
		return root
	}
	if key == nodes[root].lo {
		nodes[root].lo++
		return root
	}
	if key == nodes[root].hi {
		nodes[root].hi--
		return root
	}
	piece := diet_new(mut nodes, mut used, key + 1, nodes[root].hi, -1, nodes[root].right)
	nodes[root].hi = key - 1
	nodes[root].right = piece
	interval_count++
	return root
}

fn diet_contains(nodes []DietNode, root_input int, key i64) bool {
	mut root := root_input
	for root >= 0 {
		if key < nodes[root].lo {
			root = nodes[root].left
		} else if key > nodes[root].hi {
			root = nodes[root].right
		} else {
			return true
		}
	}
	return false
}

@[export: 'discrete_interval_encoding_tree']
pub fn discrete_interval_encoding_tree(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 1 || length > 2 + 2 * diet_max_q {
		return -1
	}
	q_value := unsafe { input[0] }
	if q_value < 0 || q_value > i64(diet_max_q) {
		return -1
	}
	q := int(q_value)
	if length != usize(1 + 2 * q) {
		return -1
	}
	for op in 0 .. q {
		opcode := unsafe { input[1 + 2 * op] }
		key := unsafe { input[2 + 2 * op] }
		if opcode < 0 || opcode > 2 || key < diet_min_key || key > diet_max_key {
			return -1
		}
	}
	required := 8 * q
	if required > 0 && (unsafe { output == nil } || capacity < usize(required)) {
		return -2
	}
	if required == 0 {
		return 0
	}

	mut nodes := [diet_arena]DietNode{}
	mut used := 0
	mut root := -1
	mut cardinality := 0
	mut interval_count := 0
	mut staged := [diet_max_q]i64{}
	for op in 0 .. q {
		opcode := unsafe { input[1 + 2 * op] }
		key := unsafe { input[2 + 2 * op] }
		mut changed := false
		if opcode == 0 {
			root = diet_insert(mut nodes[..], mut used, root, key,
				mut interval_count, mut changed)
			if changed { cardinality++ }
		} else if opcode == 1 {
			root = diet_erase(mut nodes[..], mut used, root, key,
				mut interval_count, mut changed)
			if changed { cardinality-- }
		}
		present := i64(0)
		if diet_contains(nodes[..], root, key) { present = 1 }
		staged[op] = 64 * i64(cardinality) + 2 * i64(interval_count) + present
	}
	for op in 0 .. q {
		word := u64(staged[op])
		for byte in 0 .. 8 {
			unsafe { output[8 * op + byte] = u8(word >> (8 * byte)) }
		}
	}
	return i64(required)
}
