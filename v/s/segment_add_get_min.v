module segment_add_get_min

const max_initial_segments = 16
const max_operations = 32
const domain_low = i64(-32)
const domain_high = i64(31)
const domain_right = i64(32)
const coefficient_limit = i64(1000)
const infinity_value = i64(1_000_000_000_000)
const checksum_offset = i64(33_001)
const tree_capacity = 4 * 64 + 8
const max_input_length = 2 + 4 * 16 + 5 * 32

struct LineNode {
	mut:
	slope i64
	intercept i64
	occupied bool
}

struct SegmentLiChao {
	mut:
	nodes [tree_capacity]LineNode
}

fn evaluate(slope i64, intercept i64, x i64) i64 {
	return slope * x + intercept
}

fn add_line(mut tree SegmentLiChao, node int, low i64, high i64, new_slope i64, new_intercept i64) {
	if !tree.nodes[node].occupied {
		tree.nodes[node].slope = new_slope
		tree.nodes[node].intercept = new_intercept
		tree.nodes[node].occupied = true
		return
	}
	middle := low + (high - low) / 2
	mut slope := new_slope
	mut intercept := new_intercept
	if evaluate(slope, intercept, middle) < evaluate(tree.nodes[node].slope, tree.nodes[node].intercept, middle) {
		slope, tree.nodes[node].slope = tree.nodes[node].slope, slope
		intercept, tree.nodes[node].intercept = tree.nodes[node].intercept, intercept
	}
	if low == high { return }
	if evaluate(slope, intercept, low) < evaluate(tree.nodes[node].slope, tree.nodes[node].intercept, low) {
		add_line(mut tree, 2 * node, low, middle, slope, intercept)
	} else if evaluate(slope, intercept, high) < evaluate(tree.nodes[node].slope, tree.nodes[node].intercept, high) {
		add_line(mut tree, 2 * node + 1, middle + 1, high, slope, intercept)
	}
}

fn add_segment(mut tree SegmentLiChao, node int, low i64, high i64, query_low i64, query_high i64, slope i64, intercept i64) {
	if query_high <= low || high < query_low { return }
	if query_low <= low && high < query_high {
		add_line(mut tree, node, low, high, slope, intercept)
		return
	}
	middle := low + (high - low) / 2
	add_segment(mut tree, 2 * node, low, middle, query_low, query_high, slope, intercept)
	add_segment(mut tree, 2 * node + 1, middle + 1, high, query_low, query_high, slope, intercept)
}

fn minimum_at(tree &SegmentLiChao, node int, low i64, high i64, x i64) i64 {
	mut best := infinity_value
	if tree.nodes[node].occupied { best = evaluate(tree.nodes[node].slope, tree.nodes[node].intercept, x) }
	if low == high { return best }
	middle := low + (high - low) / 2
	go_left := x <= middle
	child := if go_left { 2 * node } else { 2 * node + 1 }
	nested := minimum_at(tree, child, if go_left { low } else { middle + 1 }, if go_left { middle } else { high }, x)
	if nested < best { best = nested }
	return best
}

fn valid_segment(left i64, right i64, slope i64, intercept i64) bool {
	return left >= domain_low && left < right && right <= domain_right &&
		slope >= -coefficient_limit && slope <= coefficient_limit &&
		intercept >= -coefficient_limit && intercept <= coefficient_limit
}

@[export: 'segment_add_get_min']
pub fn segment_add_get_min(values &i64, length usize) i64 {
	if unsafe { values == nil } || length < 2 || length > max_input_length { return -1 }
	initial_value := unsafe { values[0] }
	operation_value := unsafe { values[1] }
	if initial_value < 0 || initial_value > max_initial_segments || operation_value < 0 || operation_value > max_operations { return -1 }
	initial_count := int(initial_value)
	operation_count := int(operation_value)

	mut tree := SegmentLiChao{}
	mut position := 2
	for _ in 0 .. initial_count {
		if int(length) - position < 4 { return -1 }
		left := unsafe { values[position] }
		right := unsafe { values[position + 1] }
		slope := unsafe { values[position + 2] }
		intercept := unsafe { values[position + 3] }
		if !valid_segment(left, right, slope, intercept) { return -1 }
		add_segment(mut tree, 1, domain_low, domain_high, left, right, slope, intercept)
		position += 4
	}

	mut checksum := i64(0)
	mut query_number := i64(0)
	for _ in 0 .. operation_count {
		if position >= int(length) { return -1 }
		opcode := unsafe { values[position] }
		position++
		if opcode == 0 {
			if int(length) - position < 4 { return -1 }
			left := unsafe { values[position] }
			right := unsafe { values[position + 1] }
			slope := unsafe { values[position + 2] }
			intercept := unsafe { values[position + 3] }
			if !valid_segment(left, right, slope, intercept) { return -1 }
			add_segment(mut tree, 1, domain_low, domain_high, left, right, slope, intercept)
			position += 4
		} else if opcode == 1 {
			if position >= int(length) { return -1 }
			x := unsafe { values[position] }
			position++
			if x < domain_low || x > domain_high { return -1 }
			answer := minimum_at(tree, 1, domain_low, domain_high, x)
			query_number++
			checksum += query_number * (answer + checksum_offset)
		} else {
			return -1
		}
	}
	if position != int(length) { return -1 }
	return checksum
}
