@[export: 'arpa_offline_rmq']
pub fn arpa_offline_rmq(input &i64, length usize) i64 {
	if length < 2 || length > 195 { return -1 }
	unsafe {
		if input == nil { return -1 }
		n_value, q_value := input[0], input[1]
		if n_value < 1 || n_value > 64 || q_value < 0 || q_value > 64 { return -1 }
		n, q := int(n_value), int(q_value)
		if length != usize(2 + n + 2*q) { return -1 }
		for i in 0 .. n { if input[2+i] < -1000 || input[2+i] > 1000 { return -1 } }
		query_start := 2 + n
		for j in 0 .. q {
			left, right := input[query_start+2*j], input[query_start+2*j+1]
			if left < 0 || left > right || right >= n_value { return -1 }
		}
		mut parent := [64]i64{}
		mut stack := [64]i64{}
		mut head := [64]i64{}
		mut next_query := [64]i64{}
		for i in 0 .. n { parent[i] = i64(i); head[i] = -1 }
		for j in 0 .. q {
			right := int(input[query_start+2*j+1])
			next_query[j] = head[right]
			head[right] = i64(j)
		}
		mut stack_size := 0
		mut checksum := i64(0)
		for right in 0 .. n {
			for stack_size > 0 && input[2+int(stack[stack_size-1])] > input[2+right] {
				stack_size--
				parent[int(stack[stack_size])] = i64(right)
			}
			stack[stack_size] = i64(right)
			stack_size++
			mut query := head[right]
			for query >= 0 {
				ordinal := int(query)
				mut node := int(input[query_start+2*ordinal])
				mut root := node
				for int(parent[root]) != root { root = int(parent[root]) }
				for int(parent[node]) != node {
					next := int(parent[node])
					parent[node] = i64(root)
					node = next
				}
				checksum += i64(ordinal+1) * i64(root+1)
				query = next_query[ordinal]
			}
		}
		return checksum
	}
}
