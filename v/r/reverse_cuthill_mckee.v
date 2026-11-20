module reverse_cuthill_mckee

const max_vertices = 8
const max_edges = 28
const max_input_length = 59

@[export: 'reverse_cuthill_mckee']
pub fn reverse_cuthill_mckee(input &i64, length usize) i64 {
	if input == nil || length < 2 || length > max_input_length { return -1 }
	unsafe {
		n_value, m_value := input[0], input[1]
		if n_value < 1 || n_value > max_vertices || m_value < 0 || m_value > max_edges { return -1 }
		n, m := int(n_value), int(m_value)
		if m > n * (n - 1) / 2 || int(length) != 2 + 2 * m { return -1 }

		mut adjacency := [max_vertices * max_vertices]bool{}
		for edge in 0 .. m {
			left_value, right_value := input[2 + 2 * edge], input[3 + 2 * edge]
			if left_value < 0 || left_value >= n_value || right_value < 0 || right_value >= n_value
				|| left_value == right_value { return -1 }
			left, right := int(left_value), int(right_value)
			forward, backward := left * max_vertices + right, right * max_vertices + left
			if adjacency[forward] || adjacency[backward] { return -1 }
			adjacency[forward], adjacency[backward] = true, true
		}

		mut degree := [max_vertices]int{}
		for vertex in 0 .. n {
			for neighbor in 0 .. n {
				if adjacency[vertex * max_vertices + neighbor] { degree[vertex]++ }
			}
		}

		mut visited := [max_vertices]bool{}
		mut queue := [max_vertices]int{}
		mut order := [max_vertices]int{}
		mut order_length, mut visited_count := 0, 0
		for visited_count < n {
			mut root := n
			for vertex in 0 .. n {
				if visited[vertex] { continue }
				if root == n || degree[vertex] < degree[root]
					|| (degree[vertex] == degree[root] && vertex < root) { root = vertex }
			}

			mut head, mut tail := 0, 1
			queue[0] = root
			visited[root] = true
			visited_count++
			order[order_length] = root
			order_length++
			for head < tail {
				vertex := queue[head]
				head++
				mut fresh := [max_vertices]int{}
				mut fresh_count := 0
				for neighbor in 0 .. n {
					if !adjacency[vertex * max_vertices + neighbor] || visited[neighbor] { continue }
					mut insert_at := fresh_count
					for insert_at > 0 {
						previous := fresh[insert_at - 1]
						if degree[previous] < degree[neighbor]
							|| (degree[previous] == degree[neighbor] && previous < neighbor) { break }
						fresh[insert_at] = previous
						insert_at--
					}
					fresh[insert_at] = neighbor
					fresh_count++
				}
				for index in 0 .. fresh_count {
					neighbor := fresh[index]
					visited[neighbor] = true
					visited_count++
					queue[tail] = neighbor
					tail++
					order[order_length] = neighbor
					order_length++
				}
			}
		}

		mut left, mut right := 0, order_length
		for left < right {
			right--
			if left >= right { break }
			temporary := order[left]
			order[left], order[right] = order[right], temporary
			left++
		}

		mut position := [max_vertices]int{}
		mut rank_word := i64(0)
		for rank in 0 .. n {
			vertex := order[rank]
			position[vertex] = rank
			rank_word |= i64(vertex) << (3 * rank)
		}
		mut bandwidth := 0
		for left_vertex in 0 .. n {
			for right_vertex in left_vertex + 1 .. n {
				if adjacency[left_vertex * max_vertices + right_vertex] {
					difference := if position[left_vertex] >= position[right_vertex]
						{ position[left_vertex] - position[right_vertex] }
						else { position[right_vertex] - position[left_vertex] }
					if difference > bandwidth { bandwidth = difference }
				}
			}
		}
		return (i64(bandwidth) << 24) | rank_word
	}
}
