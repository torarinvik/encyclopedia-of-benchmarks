module list_ranking_independent_set_contraction

const max_n = 16
const max_input = 34
const max_output = 128

@[export: 'list_ranking_independent_set_contraction']
pub fn list_ranking_independent_set_contraction(input &i64, length usize,
	output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 4 || length > max_input { return -1 }
		n64, head64 := input[0], input[1]
		if n64 < 1 || n64 > max_n || length != usize(2 + 2*n64) || head64 < 0 || head64 >= n64 { return -1 }
		n, head := int(n64), int(head64)
		mut weight := [max_n]i64{init: 0}
		mut successor := [max_n]i64{init: 0}
		mut indegree := [max_n]int{init: 0}
		mut tail_count := 0
		for node in 0 .. n {
			weight[node] = input[2 + node]
			successor[node] = input[2 + n + node]
			if weight[node] < 1 || weight[node] > 10000 || successor[node] < -1 || successor[node] >= n64 { return -1 }
			if successor[node] == -1 { tail_count++ } else {
				next := int(successor[node])
				indegree[next]++
				if indegree[next] > 1 { return -1 }
			}
		}
		if tail_count != 1 || indegree[head] != 0 { return -1 }

		mut path := [max_n]int{init: 0}
		mut seen := [max_n]bool{init: false}
		mut path_length := 0
		mut node := head64
		for node != -1 {
			index := int(node)
			if seen[index] || path_length == n { return -1 }
			seen[index] = true
			path[path_length] = index
			path_length++
			node = successor[index]
		}
		if path_length != n { return -1 }
		output_bytes := 8*n
		if output == nil || capacity < output_bytes { return -2 }

		mut removed_node := [max_n]int{init: 0}
		mut removed_successor := [max_n]int{init: 0}
		mut old_successor_weight := [max_n]i64{init: 0}
		mut removed_count := 0
		for path_length > 1 {
			mut counts := [3]int{init: 0}
			for position in 0 .. (path_length - 1) { counts[position % 3]++ }
			mut color := 0
			for candidate in 1 .. 3 { if counts[candidate] > counts[color] { color = candidate } }
			mut write := 0
			for position in 0 .. path_length {
				current := path[position]
				if position + 1 < path_length && position % 3 == color {
					next := path[position + 1]
					removed_node[removed_count] = current
					removed_successor[removed_count] = next
					old_successor_weight[removed_count] = weight[next]
					removed_count++
					weight[next] += weight[current]
				} else {
					path[write] = current
					write++
				}
			}
			if write == path_length { return -1 }
			path_length = write
		}

		mut rank := [max_n]i64{init: 0}
		rank[path[0]] = weight[path[0]]
		for removed_count > 0 {
			removed_count--
			current, next := removed_node[removed_count], removed_successor[removed_count]
			rank[current] = rank[next] - old_successor_weight[removed_count]
		}
		mut staged := [max_output]u8{init: 0}
		for index in 0 .. n {
			bits := u64(rank[index])
			for byte in 0 .. 8 { staged[8*index + byte] = u8((bits >> (8*byte)) & 255) }
		}
		for index in 0 .. output_bytes { output[index] = staged[index] }
		return i64(output_bytes)
	}
}
