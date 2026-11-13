const max_n = 32
const max_q = 32
const max_input_length = 131
const max_nodes = 193
const invalid_result = i64(-9223372036854775807) - 1

@[export: 'persistent_segment_tree_range_kth']
pub fn persistent_segment_tree_range_kth(input &i64, length usize) i64 {
	if length < 2 || length > max_input_length { return invalid_result }
	unsafe {
		if input == nil || input[0] < 1 || input[0] > max_n || input[1] < 0 || input[1] > max_q {
			return invalid_result
		}
		n := int(input[0])
		q := int(input[1])
		if length != usize(2+n+3*q) { return invalid_result }
		mut coordinates := [max_n]i64{}
		for i in 0 .. n {
			value := input[2+i]
			if value < -1000 || value > 1000 { return invalid_result }
			coordinates[i] = value
		}
		for i in 1 .. n {
			value := coordinates[i]
			mut j := i
			for j > 0 && coordinates[j-1] > value {
				coordinates[j] = coordinates[j-1]
				j--
			}
			coordinates[j] = value
		}
		mut distinct := 0
		for i in 0 .. n {
			if distinct == 0 || coordinates[i] != coordinates[distinct-1] {
				coordinates[distinct] = coordinates[i]
				distinct++
			}
		}
		query_offset := 2+n
		for qi in 0 .. q {
			left := input[query_offset+3*qi]
			right := input[query_offset+3*qi+1]
			k := input[query_offset+3*qi+2]
			if left < 0 || right < left || right >= i64(n) || k < 1 || k > right-left+1 {
				return invalid_result
			}
		}

		mut left_child := [max_nodes]i32{}
		mut right_child := [max_nodes]i32{}
		mut counts := [max_nodes]i32{}
		mut roots := [max_n+1]i32{}
		mut node_count := 1
		for i in 0 .. n {
			value := input[2+i]
			mut low := 0
			mut high := distinct
			for low < high {
				middle := low+(high-low)/2
				if coordinates[middle] < value { low = middle+1 } else { high = middle }
			}
			rank := low
			previous_root := int(roots[i])
			if node_count >= max_nodes { return invalid_result }
			new_root := node_count
			node_count++
			left_child[new_root] = left_child[previous_root]
			right_child[new_root] = right_child[previous_root]
			counts[new_root] = counts[previous_root]+1
			mut old_node := previous_root
			mut new_node := new_root
			low = 0
			high = distinct
			for high-low > 1 {
				middle := low+(high-low)/2
				mut old_child := int(left_child[old_node])
				if rank >= middle { old_child = int(right_child[old_node]) }
				if node_count >= max_nodes { return invalid_result }
				new_child := node_count
				node_count++
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

		mut checksum := i64(0)
		for qi in 0 .. q {
			offset := query_offset+3*qi
			left := int(input[offset])
			right := int(input[offset+1])
			mut k := int(input[offset+2])
			mut before := int(roots[left])
			mut after := int(roots[right+1])
			mut low := 0
			mut high := distinct
			for high-low > 1 {
				middle := low+(high-low)/2
				in_left := int(left_child[after])
				out_left := int(left_child[before])
				left_count := int(counts[in_left]-counts[out_left])
				if k <= left_count { before = out_left; after = in_left; high = middle }
				else { k -= left_count; before = int(right_child[before]); after = int(right_child[after]); low = middle }
			}
			checksum += i64(qi+1)*coordinates[low]
		}
		return checksum
	}
}
