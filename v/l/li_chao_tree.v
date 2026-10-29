module li_chao_tree

const max_operations = 512
const max_nodes = max_operations * 24 + 1
const domain_low = i64(-1_000_000)
const domain_high = i64(1_000_000)
const coefficient_limit = i64(1_000)
const checksum_offset = i64(1_000_001_001)

struct LineNode {
	mut:
	slope i64
	intercept i64
	left int
	right int
	occupied bool
}

struct LiChaoTree {
	mut:
	nodes [max_nodes]LineNode
	used int
	root int
}

fn evaluate(slope i64, intercept i64, x i64) i64 {
	return slope * x + intercept
}

fn allocate(mut tree LiChaoTree) int {
	if tree.used >= max_nodes { return -1 }
	id := tree.used
	tree.used++
	tree.nodes[id].left = -1
	tree.nodes[id].right = -1
	tree.nodes[id].occupied = false
	return id
}

fn insert_at(mut tree LiChaoTree, id int, low i64, high i64, new_slope i64, new_intercept i64) bool {
	if !tree.nodes[id].occupied {
		tree.nodes[id].slope = new_slope
		tree.nodes[id].intercept = new_intercept
		tree.nodes[id].occupied = true
		return true
	}

	middle := low + (high - low) / 2
	mut slope := new_slope
	mut intercept := new_intercept
	if evaluate(slope, intercept, middle) < evaluate(tree.nodes[id].slope, tree.nodes[id].intercept, middle) {
		slope, tree.nodes[id].slope = tree.nodes[id].slope, slope
		intercept, tree.nodes[id].intercept = tree.nodes[id].intercept, intercept
	}
	if low == high { return true }

	mut go_left := false
	mut next_low := middle + 1
	mut next_high := high
	if evaluate(slope, intercept, low) < evaluate(tree.nodes[id].slope, tree.nodes[id].intercept, low) {
		go_left = true
		next_low = low
		next_high = middle
	} else if evaluate(slope, intercept, high) >= evaluate(tree.nodes[id].slope, tree.nodes[id].intercept, high) {
		return true
	}

	mut child := tree.nodes[id].right
	if go_left { child = tree.nodes[id].left }
	if child < 0 {
		child = allocate(mut tree)
		if child < 0 { return false }
		if go_left { tree.nodes[id].left = child } else { tree.nodes[id].right = child }
	}
	return insert_at(mut tree, child, next_low, next_high, slope, intercept)
}

fn add_line(mut tree LiChaoTree, slope i64, intercept i64) bool {
	if tree.root < 0 {
		tree.root = allocate(mut tree)
		if tree.root < 0 { return false }
	}
	return insert_at(mut tree, tree.root, domain_low, domain_high, slope, intercept)
}

fn minimum_at(tree &LiChaoTree, id int, low i64, high i64, x i64) i64 {
	node := tree.nodes[id]
	mut best := evaluate(node.slope, node.intercept, x)
	if low == high { return best }
	middle := low + (high - low) / 2
	go_left := x <= middle
	child := node.right
	if go_left { child = node.left }
	if child >= 0 {
		nested := minimum_at(tree, child, if go_left { low } else { middle + 1 }, if go_left { middle } else { high }, x)
		if nested < best { best = nested }
	}
	return best
}

@[export: 'li_chao_tree']
pub fn li_chao_tree(values &i64, length usize) i64 {
	if unsafe { values == nil } || length < 1 || length > 1 + 3 * max_operations { return -1 }
	if unsafe { values[0] < 0 || values[0] > max_operations } { return -1 }
	operation_count := int(unsafe { values[0] })
	if length != 1 + 3 * operation_count { return -1 }

	mut tree := LiChaoTree{root: -1}
	mut inserted := 0
	mut query_number := i64(0)
	mut checksum := i64(0)
	for operation in 0 .. operation_count {
		offset := 1 + 3 * operation
		opcode := unsafe { values[offset] }
		first := unsafe { values[offset + 1] }
		second := unsafe { values[offset + 2] }
		if opcode == 0 {
			if first < -coefficient_limit || first > coefficient_limit || second < -coefficient_limit || second > coefficient_limit { return -1 }
			if !add_line(mut tree, first, second) { return -1 }
			inserted++
		} else if opcode == 1 {
			if first < domain_low || first > domain_high || second != 0 || inserted == 0 { return -1 }
			answer := minimum_at(tree, tree.root, domain_low, domain_high, first)
			query_number++
			checksum += query_number * (answer + checksum_offset)
		} else {
			return -1
		}
	}
	return checksum
}
