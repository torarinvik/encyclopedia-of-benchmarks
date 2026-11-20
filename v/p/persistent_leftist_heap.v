module persistent_leftist_heap

const max_operations = 64
const max_nodes = 1024
const max_input_words = 193
const max_heap_size = 128

struct HeapNode {
mut:
	key i64
	left int
	right int
	npl int
	size int
}

fn meld(mut nodes &HeapNode, mut used &int, first_root int, second_root int) int {
	unsafe {
		if first_root == 0 { return second_root }
		if second_root == 0 { return first_root }
		mut first, mut second := first_root, second_root
		if nodes[first].key > nodes[second].key { first, second = second, first }
		if used >= max_nodes { return -1 }
		copy := used
		used++
		nodes[copy] = nodes[first]
		merged_right := meld(mut nodes, mut used, nodes[copy].right, second)
		if merged_right < 0 { return -1 }
		nodes[copy].right = merged_right
		if nodes[nodes[copy].left].npl < nodes[nodes[copy].right].npl {
			nodes[copy].left, nodes[copy].right = nodes[copy].right, nodes[copy].left
		}
		nodes[copy].npl = nodes[nodes[copy].right].npl + 1
		nodes[copy].size = nodes[nodes[copy].left].size + nodes[nodes[copy].right].size + 1
		return copy
	}
}

@[export: 'persistent_leftist_heap']
pub fn persistent_leftist_heap(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 1 || length > max_input_words { return -1 }
		operation_count64 := input[0]
		if operation_count64 < 0 || operation_count64 > max_operations { return -1 }
		operation_count, input_length := int(operation_count64), int(length)
		mut nodes := [max_nodes]HeapNode{}
		nodes[0].npl = -1
		mut used := 1
		mut roots := [max_operations + 1]int{}
		mut cursor := 1
		mut rank_sum, rank_xor := i64(0), i64(0)
		for operation in 0 .. operation_count {
			if cursor >= input_length { return -1 }
			kind := input[cursor]
			cursor++
			if kind == 0 {
				if cursor + 2 > input_length { return -1 }
				base64, key := input[cursor], input[cursor + 1]
				cursor += 2
				if base64 < 0 || base64 > i64(operation) || key < -10000 || key > 10000 { return -1 }
				base := int(base64)
				if nodes[roots[base]].size >= max_heap_size || used >= max_nodes { return -1 }
				singleton := used
				used++
				nodes[singleton] = HeapNode{key: key, npl: 0, size: 1}
				result_root := meld(mut nodes[0], mut used, roots[base], singleton)
				if result_root < 0 || nodes[result_root].size > max_heap_size { return -1 }
				roots[operation + 1] = result_root
			} else if kind == 1 {
				if cursor + 2 > input_length { return -1 }
				left64, right64 := input[cursor], input[cursor + 1]
				cursor += 2
				if left64 < 0 || left64 > i64(operation) || right64 < 0 || right64 > i64(operation) { return -1 }
				left_version, right_version := int(left64), int(right64)
				if nodes[roots[left_version]].size + nodes[roots[right_version]].size > max_heap_size { return -1 }
				result_root := meld(mut nodes[0], mut used, roots[left_version], roots[right_version])
				if result_root < 0 || nodes[result_root].size > max_heap_size { return -1 }
				roots[operation + 1] = result_root
			} else if kind == 2 {
				if cursor + 1 > input_length { return -1 }
				version64 := input[cursor]
				cursor++
				if version64 < 0 || version64 > i64(operation) { return -1 }
				root := roots[int(version64)]
				if root == 0 {
					roots[operation + 1] = 0
					rank_sum += 20001
					rank_xor ^= 20001
				} else {
					rank := nodes[root].key + 10000
					rank_sum += rank
					rank_xor ^= rank
					result_root := meld(mut nodes[0], mut used, nodes[root].left, nodes[root].right)
					if result_root < 0 || nodes[result_root].size > max_heap_size { return -1 }
					roots[operation + 1] = result_root
				}
			} else if kind == 3 {
				if cursor + 1 > input_length { return -1 }
				version64 := input[cursor]
				cursor++
				if version64 < 0 || version64 > i64(operation) { return -1 }
				root := roots[int(version64)]
				roots[operation + 1] = root
				rank := i64(20001)
				if root != 0 { rank = nodes[root].key + 10000 }
				rank_sum += rank
				rank_xor ^= rank
			} else {
				return -1
			}
		}
		if cursor != input_length { return -1 }
		return (rank_sum << 15) | rank_xor
	}
}
