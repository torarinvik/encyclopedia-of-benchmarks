module dag_shortest_path

const max_vertices = 12
const max_edges = 66
const max_length = 203
const distance_offset = i64(100000)
const infinity_distance = i64(1) << 60

@[export: 'dag_shortest_path']
pub fn dag_shortest_path(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 4 || length > max_length { return -1 }
		if input[0] < 1 || input[0] > max_vertices || input[1] < 0 || input[1] > max_edges { return -1 }
		vertex_count := int(input[0])
		edge_count := int(input[1])
		if length != usize(4+3*edge_count) { return -1 }
		if input[2] < 0 || input[2] >= i64(vertex_count) || input[3] < 0 || input[3] >= i64(vertex_count) { return -1 }
		mut from := [max_edges]i64{}
		mut to := [max_edges]i64{}
		mut weight := [max_edges]i64{}
		mut indegree := [max_vertices]i64{}
		for edge in 0 .. edge_count {
			start := input[4+3*edge]
			finish := input[5+3*edge]
			cost := input[6+3*edge]
			if start < 0 || start >= i64(vertex_count) || finish < 0 || finish >= i64(vertex_count) || start == finish || cost < -1000 || cost > 1000 { return -1 }
			for previous in 0 .. edge {
				if from[previous] == start && to[previous] == finish { return -1 }
			}
			from[edge] = start
			to[edge] = finish
			weight[edge] = cost
			indegree[int(finish)]++
		}
		mut queue := [max_vertices]int{}
		mut order := [max_vertices]int{}
		mut head := 0
		mut tail := 0
		for vertex in 0 .. vertex_count {
			if indegree[vertex] == 0 { queue[tail] = vertex; tail++ }
		}
		mut order_count := 0
		for head < tail {
			vertex := queue[head]
			head++
			order[order_count] = vertex
			order_count++
			for edge in 0 .. edge_count {
				if from[edge] == i64(vertex) {
					finish := int(to[edge])
					indegree[finish]--
					if indegree[finish] == 0 { queue[tail] = finish; tail++ }
				}
			}
		}
		if order_count != vertex_count { return -1 }
		mut distance := [max_vertices]i64{}
		for vertex in 0 .. vertex_count { distance[vertex] = infinity_distance }
		distance[int(input[2])] = 0
		for position in 0 .. vertex_count {
			vertex := order[position]
			if distance[vertex] == infinity_distance { continue }
			for edge in 0 .. edge_count {
				if from[edge] == i64(vertex) {
					finish := int(to[edge])
					candidate := distance[vertex]+weight[edge]
					if candidate < distance[finish] { distance[finish] = candidate }
				}
			}
		}
		answer := distance[int(input[3])]
		if answer == infinity_distance { return 0 }
		return distance_offset + answer
	}
}
