module persistent_queue

const max_q = 128
const tree_base = 128
const tree_height = 7
const max_nodes = 1 + max_q * (tree_height + 1)
const max_parseable_input = 1 + 3 * max_q + 1
const max_value = i64(1000000000)

struct Node { left int; right int; value i64 }

fn set_value(mut nodes &Node, mut used &int, root int, low int, high int,
    position int, value i64) int {
	unsafe {
		copy := used
		used++
		nodes[copy] = nodes[root]
		if high-low == 1 {
			nodes[copy].value = value
			return copy
		}
		middle := low + (high-low)/2
		if position < middle {
			child := set_value(mut nodes, mut used, nodes[root].left,
				low, middle, position, value)
			nodes[copy].left = child
		} else {
			child := set_value(mut nodes, mut used, nodes[root].right,
				middle, high, position, value)
			nodes[copy].right = child
		}
		return copy
	}
}

fn get_value(nodes &Node, root int, low int, high int, position int) i64 {
	unsafe {
		if high-low == 1 { return nodes[root].value }
		middle := low + (high-low)/2
		if position < middle {
			return get_value(nodes, nodes[root].left, low, middle, position)
		}
		return get_value(nodes, nodes[root].right, middle, high, position)
	}
}

fn store_i64_le(mut output &u8, offset int, value i64) {
	unsafe {
		mut bits := u64(value)
		for byte in 0 .. 8 {
			output[offset+byte] = u8(bits & 255)
			bits >>= 8
		}
	}
}

@[export: 'persistent_queue']
pub fn persistent_queue(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 1 || length > usize(max_parseable_input) { return -1 }
	unsafe {
		qv := input[0]
		if qv < 1 || qv > max_q { return -1 }
		q := int(qv)
		mut kind := [max_q]i64{}
		mut parent := [max_q]i64{}
		mut value := [max_q]i64{}
		mut version_head := [max_q+1]int{}
		mut version_tail := [max_q+1]int{}
		mut version_size := [max_q+1]int{}
		mut cursor, pop_count := 1, 0
		for operation in 0 .. q {
			if cursor+2 > int(length) { return -1 }
			kind[operation] = input[cursor]
			cursor++
			parent[operation] = input[cursor]
			cursor++
			if (kind[operation] != 0 && kind[operation] != 1) || parent[operation] < -1 || parent[operation] >= i64(operation) { return -1 }
			base := int(parent[operation]+1)
			if kind[operation] == 0 {
				if cursor >= int(length) { return -1 }
				value[operation] = input[cursor]
				cursor++
				if value[operation] < 0 || value[operation] > max_value || version_tail[base] >= tree_base { return -1 }
				version_head[operation+1] = version_head[base]
				version_tail[operation+1] = version_tail[base]+1
				version_size[operation+1] = version_size[base]+1
			} else {
				if version_size[base] == 0 { return -1 }
				version_head[operation+1] = version_head[base]+1
				version_tail[operation+1] = version_tail[base]
				version_size[operation+1] = version_size[base]-1
				pop_count++
			}
		}
		if cursor != int(length) { return -1 }
		required := 8*pop_count
		if required > 0 && (unsafe { output == nil } || capacity < usize(required)) { return -2 }
		mut nodes := [max_nodes]Node{}
		mut roots := [max_q+1]int{}
		mut answers := [max_q]i64{}
		mut used, answer_count := 1, 0
		for operation in 0 .. q {
			base := int(parent[operation]+1)
			version := operation+1
			if kind[operation] == 0 {
				roots[version] = set_value(mut nodes[0], mut used, roots[base], 0, tree_base,
					version_tail[base], value[operation])
			} else {
				answers[answer_count] = get_value(nodes[0], roots[base], 0, tree_base, version_head[base])
				answer_count++
				roots[version] = roots[base]
			}
		}
		for index in 0 .. answer_count { store_i64_le(mut output, 8*index, answers[index]) }
		return i64(required)
	}
}
