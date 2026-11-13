package persistent_segment_tree_range_kth

import "core:c"

MAX_N :: 32
MAX_Q :: 32
MAX_INPUT_LENGTH :: 131
MAX_NODES :: 193
INVALID_RESULT :: i64 = -9223372036854775807 - 1

@(export)
persistent_segment_tree_range_kth :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 2 || length > MAX_INPUT_LENGTH do return INVALID_RESULT
	if input[0] < 1 || input[0] > MAX_N || input[1] < 0 || input[1] > MAX_Q do return INVALID_RESULT
	n := int(input[0])
	q := int(input[1])
	if int(length) != 2+n+3*q do return INVALID_RESULT

	var coordinates: [MAX_N]i64
	for i := 0; i < n; i += 1 {
		value := input[2+i]
		if value < -1000 || value > 1000 do return INVALID_RESULT
		coordinates[i] = value
	}
	for i := 1; i < n; i += 1 {
		value := coordinates[i]
		j := i
		for j > 0 && coordinates[j-1] > value {
			coordinates[j] = coordinates[j-1]
			j -= 1
		}
		coordinates[j] = value
	}
	distinct := 0
	for i := 0; i < n; i += 1 {
		if distinct == 0 || coordinates[i] != coordinates[distinct-1] {
			coordinates[distinct] = coordinates[i]
			distinct += 1
		}
	}
	query_offset := 2+n
	for qi := 0; qi < q; qi += 1 {
		left := input[query_offset+3*qi]
		right := input[query_offset+3*qi+1]
		k := input[query_offset+3*qi+2]
		if left < 0 || right < left || right >= i64(n) || k < 1 || k > right-left+1 do return INVALID_RESULT
	}

	var left_child: [MAX_NODES]i32
	var right_child: [MAX_NODES]i32
	var counts: [MAX_NODES]i32
	var roots: [MAX_N+1]i32
	node_count := 1
	for i := 0; i < n; i += 1 {
		value := input[2+i]
		low := 0
		high := distinct
		for low < high {
			middle := low+(high-low)/2
			if coordinates[middle] < value { low = middle+1 } else { high = middle }
		}
		rank := low
		previous_root := int(roots[i])
		if node_count >= MAX_NODES do return INVALID_RESULT
		new_root := node_count
		node_count += 1
		left_child[new_root] = left_child[previous_root]
		right_child[new_root] = right_child[previous_root]
		counts[new_root] = counts[previous_root]+1
		old_node := previous_root
		new_node := new_root
		low = 0
		high = distinct
		for high-low > 1 {
			middle := low+(high-low)/2
			old_child := int(left_child[old_node])
			if rank >= middle { old_child = int(right_child[old_node]) }
			if node_count >= MAX_NODES do return INVALID_RESULT
			new_child := node_count
			node_count += 1
			left_child[new_child] = left_child[old_child]
			right_child[new_child] = right_child[old_child]
			counts[new_child] = counts[old_child]+1
			if rank < middle { left_child[new_node] = i32(new_child); high = middle }
			else { right_child[new_node] = i32(new_child); low = middle }
			old_node = old_child
			new_node = new_child
		}
		roots[i+1] = i32(new_root)
	}

	checksum: i64 = 0
	for qi := 0; qi < q; qi += 1 {
		offset := query_offset+3*qi
		left := int(input[offset])
		right := int(input[offset+1])
		k := int(input[offset+2])
		before := int(roots[left])
		after := int(roots[right+1])
		low := 0
		high := distinct
		for high-low > 1 {
			middle := low+(high-low)/2
			in_left := int(left_child[after])
			out_left := int(left_child[before])
			left_count := int(counts[in_left]-counts[out_left])
			if k <= left_count { before = out_left; after = in_left; high = middle }
			else { k -= left_count; before = int(right_child[before]); after = int(right_child[after]); low = middle }
		}
		checksum += (i64(qi)+1)*coordinates[low]
	}
	return checksum
}
