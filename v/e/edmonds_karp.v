module edmonds_karp

const max_vertices = 16
const max_capacity = i64(1_000_000)

@[export: 'edmonds_karp']
pub fn edmonds_karp(input &i64, length usize) i64 {
	if unsafe { input == nil } || length < 3 { return -1 }
	n64 := unsafe { input[0] }
	source64 := unsafe { input[1] }
	sink64 := unsafe { input[2] }
	if n64 < 1 || n64 > max_vertices || source64 < 0 || source64 >= n64 || sink64 < 0 || sink64 >= n64 {
		return -1
	}
	n := int(n64)
	if length != usize(3 + n * n) { return -1 }

	mut residual := [max_vertices * max_vertices]i64{}
	for row in 0 .. n {
		for column in 0 .. n {
			capacity := unsafe { input[3 + row * n + column] }
			if capacity < 0 || capacity > max_capacity || (row == column && capacity != 0) { return -1 }
			residual[row * n + column] = capacity
		}
	}
	for left in 0 .. n {
		for right in left + 1 .. n {
			if residual[left * n + right] > 0 && residual[right * n + left] > 0 { return -1 }
		}
	}

	source := int(source64)
	sink := int(sink64)
	if source == sink { return 0 }
	mut total_flow := i64(0)
	for {
		mut parent := [max_vertices]int{}
		mut queue := [max_vertices]int{}
		for vertex in 0 .. n { parent[vertex] = -1 }
		parent[source] = source
		mut head := 0
		mut tail := 1
		queue[0] = source
		for head < tail && parent[sink] == -1 {
			node := queue[head]
			head++
			for neighbor in 0 .. n {
				if residual[node * n + neighbor] <= 0 || parent[neighbor] != -1 { continue }
				parent[neighbor] = node
				if neighbor == sink { break }
				queue[tail] = neighbor
				tail++
			}
		}
		if parent[sink] == -1 { return total_flow }
		mut path_flow := max_capacity
		mut node := sink
		for node != source {
			previous := parent[node]
			if residual[previous * n + node] < path_flow { path_flow = residual[previous * n + node] }
			node = previous
		}
		node = sink
		for node != source {
			previous := parent[node]
			residual[previous * n + node] -= path_flow
			residual[node * n + previous] += path_flow
			node = previous
		}
		total_flow += path_flow
	}
}
