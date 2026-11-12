module segment_history_extreme

const max_n = 32
const max_q = 32
const tree_size = 4 * max_n
const max_input = 2 + max_n + 4 * max_q
const value_limit = i64(1000)

struct ShNode {
	maximum i64
	history_maximum i64
	add i64
	add_peak i64
	set_value i64
	set_peak i64
	has_set bool
}

fn sh_apply_add_summary(mut tree [tree_size]ShNode, node int, net i64, peak i64) {
	tree[node].history_maximum = if tree[node].maximum + peak > tree[node].history_maximum { tree[node].maximum + peak } else { tree[node].history_maximum }
	tree[node].maximum += net
	if tree[node].has_set {
		candidate := tree[node].set_value + peak
		if candidate > tree[node].set_peak { tree[node].set_peak = candidate }
		tree[node].set_value += net
	} else {
		candidate := tree[node].add + peak
		if candidate > tree[node].add_peak { tree[node].add_peak = candidate }
		tree[node].add += net
	}
}

fn sh_apply_add(mut tree [tree_size]ShNode, node int, delta i64) {
	if tree[node].has_set {
		candidate := tree[node].set_value + delta
		if candidate > tree[node].set_peak { tree[node].set_peak = candidate }
		tree[node].set_value += delta
	} else {
		candidate := tree[node].add + delta
		if candidate > tree[node].add_peak { tree[node].add_peak = candidate }
		tree[node].add += delta
	}
	candidate := tree[node].maximum + delta
	if candidate > tree[node].history_maximum { tree[node].history_maximum = candidate }
	tree[node].maximum += delta
}

fn sh_apply_set_summary(mut tree [tree_size]ShNode, node int, value i64, peak i64) {
	if peak > tree[node].history_maximum { tree[node].history_maximum = peak }
	tree[node].maximum = value
	if tree[node].has_set {
		if peak > tree[node].set_peak { tree[node].set_peak = peak }
	} else {
		tree[node].has_set = true
		tree[node].set_peak = peak
	}
	tree[node].set_value = value
}

fn sh_apply_set(mut tree [tree_size]ShNode, node int, value i64) {
	if value > tree[node].history_maximum { tree[node].history_maximum = value }
	tree[node].maximum = value
	if tree[node].has_set {
		if value > tree[node].set_peak { tree[node].set_peak = value }
	} else {
		tree[node].has_set = true
		tree[node].set_peak = value
	}
	tree[node].set_value = value
}

fn sh_push(mut tree [tree_size]ShNode, node int) {
	parent := tree[node]
	if parent.add != 0 || parent.add_peak != 0 {
		sh_apply_add_summary(mut tree, 2 * node, parent.add, parent.add_peak)
		sh_apply_add_summary(mut tree, 2 * node + 1, parent.add, parent.add_peak)
		tree[node].add = 0
		tree[node].add_peak = 0
	}
	if parent.has_set {
		sh_apply_set_summary(mut tree, 2 * node, parent.set_value, parent.set_peak)
		sh_apply_set_summary(mut tree, 2 * node + 1, parent.set_value, parent.set_peak)
		tree[node].has_set = false
		tree[node].set_value = 0
		tree[node].set_peak = 0
	}
}

fn sh_pull(mut tree [tree_size]ShNode, node int) {
	tree[node].maximum = if tree[2 * node].maximum > tree[2 * node + 1].maximum { tree[2 * node].maximum } else { tree[2 * node + 1].maximum }
	tree[node].history_maximum = if tree[2 * node].history_maximum > tree[2 * node + 1].history_maximum { tree[2 * node].history_maximum } else { tree[2 * node + 1].history_maximum }
}

fn sh_build(mut tree [tree_size]ShNode, values &i64, offset int, node int, left int, right int) {
	unsafe {
		if right - left == 1 {
			tree[node].maximum = values[offset + left]
			tree[node].history_maximum = values[offset + left]
			return
		}
		middle := left + (right - left) / 2
		sh_build(mut tree, values, offset, 2 * node, left, middle)
		sh_build(mut tree, values, offset, 2 * node + 1, middle, right)
		sh_pull(mut tree, node)
	}
}

fn sh_update(mut tree [tree_size]ShNode, node int, left int, right int,
	ql int, qr int, assignment bool, value i64) {
	if ql <= left && right <= qr {
		if assignment { sh_apply_set(mut tree, node, value) } else { sh_apply_add(mut tree, node, value) }
		return
	}
	sh_push(mut tree, node)
	middle := left + (right - left) / 2
	if ql < middle { sh_update(mut tree, 2 * node, left, middle, ql, qr, assignment, value) }
	if middle < qr { sh_update(mut tree, 2 * node + 1, middle, right, ql, qr, assignment, value) }
	sh_pull(mut tree, node)
}

fn sh_query(mut tree [tree_size]ShNode, node int, left int, right int,
	ql int, qr int, historical bool) i64 {
	if ql <= left && right <= qr {
		if historical { return tree[node].history_maximum }
		return tree[node].maximum
	}
	sh_push(mut tree, node)
	middle := left + (right - left) / 2
	mut answer := i64(-1_000_000_000_000)
	if ql < middle { answer = sh_query(mut tree, 2 * node, left, middle, ql, qr, historical) }
	if middle < qr {
		other := sh_query(mut tree, 2 * node + 1, middle, right, ql, qr, historical)
		if other > answer { answer = other }
	}
	return answer
}

fn sh_write_i64(mut output &u8, offset int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 { unsafe { output[offset + byte] = u8((bits >> (8 * byte)) & 255) } }
}

@[export: 'segment_history_extreme']
pub fn segment_history_extreme(input &i64, input_length usize, mut output &u8, output_capacity usize) i64 {
	unsafe {
		if input == nil || input_length < 2 || input_length > usize(max_input) { return -1 }
		n_value := input[0]
		q_value := input[1]
		if n_value < 1 || n_value > max_n || q_value < 0 || q_value > max_q { return -1 }
		n := int(n_value)
		q := int(q_value)
		if input_length != usize(2 + n + 4 * q) { return -1 }
		for i in 0 .. n {
			if input[2 + i] < -value_limit || input[2 + i] > value_limit { return -1 }
		}
		operation_offset := 2 + n
		for i in 0 .. q {
			offset := operation_offset + 4 * i
			op := input[offset]
			left := input[offset + 1]
			right := input[offset + 2]
			arg := input[offset + 3]
			if op < 0 || op > 3 || left < 0 || right <= left || right > n_value { return -1 }
			if op < 2 {
				if arg < -value_limit || arg > value_limit { return -1 }
			} else if arg != 0 { return -1 }
		}

		mut tree := [tree_size]ShNode{}
		mut staged := [max_q]i64{}
		mut answer_count := 0
		sh_build(mut tree, input, 2, 1, 0, n)
		for i in 0 .. q {
			offset := operation_offset + 4 * i
			op := int(input[offset])
			left := int(input[offset + 1])
			right := int(input[offset + 2])
			arg := input[offset + 3]
			if op < 2 {
				sh_update(mut tree, 1, 0, n, left, right, op == 0, arg)
			} else {
				staged[answer_count] = sh_query(mut tree, 1, 0, n, left, right, op == 3)
				answer_count++
			}
		}
		output_bytes := 8 * answer_count
		if output == nil || output_capacity < usize(output_bytes) { return -2 }
		for i in 0 .. answer_count { sh_write_i64(mut output, 8 * i, staged[i]) }
		return i64(output_bytes)
	}
}
