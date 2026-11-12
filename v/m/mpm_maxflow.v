module mpm_maxflow

const max_vertices = 8
const max_edges = 24
const max_input_values = 4 + 3 * max_edges + 1
const flow_infinity = i64(2401)

fn minimum(a i64, b i64) i64 { return if a < b { a } else { b } }

fn push_forward(vertex int, sink int, amount i64, n int, mut residual [8][8]i64,
	mut active [8][8]bool, mut incoming [8]i64, mut outgoing [8]i64) i64 {
	if vertex == sink { return amount }
	mut remaining := amount
	for next in 0 .. n {
		if remaining == 0 || !active[vertex][next] || residual[vertex][next] == 0 { continue }
		limit := minimum(remaining, residual[vertex][next])
		pushed := push_forward(next, sink, limit, n, mut residual, mut active, mut incoming, mut outgoing)
		if pushed == 0 { continue }
		residual[vertex][next] -= pushed
		residual[next][vertex] += pushed
		outgoing[vertex] -= pushed
		incoming[next] -= pushed
		remaining -= pushed
		if residual[vertex][next] == 0 { active[vertex][next] = false }
	}
	return amount - remaining
}

fn push_backward(vertex int, source int, amount i64, n int, mut residual [8][8]i64,
	mut active [8][8]bool, mut incoming [8]i64, mut outgoing [8]i64) i64 {
	if vertex == source { return amount }
	mut remaining := amount
	for previous in 0 .. n {
		if remaining == 0 || !active[previous][vertex] || residual[previous][vertex] == 0 { continue }
		limit := minimum(remaining, residual[previous][vertex])
		pushed := push_backward(previous, source, limit, n, mut residual, mut active, mut incoming, mut outgoing)
		if pushed == 0 { continue }
		residual[previous][vertex] -= pushed
		residual[vertex][previous] += pushed
		incoming[vertex] -= pushed
		outgoing[previous] -= pushed
		remaining -= pushed
		if residual[previous][vertex] == 0 { active[previous][vertex] = false }
	}
	return amount - remaining
}

fn remove_vertex(vertex int, n int, residual [8][8]i64, mut active [8][8]bool,
	mut incoming [8]i64, mut outgoing [8]i64, mut alive [8]bool) {
	for other in 0 .. n {
		if active[other][vertex] {
			capacity := residual[other][vertex]
			outgoing[other] -= capacity
			incoming[vertex] -= capacity
			active[other][vertex] = false
		}
		if active[vertex][other] {
			capacity := residual[vertex][other]
			outgoing[vertex] -= capacity
			incoming[other] -= capacity
			active[vertex][other] = false
		}
	}
	alive[vertex] = false
}

@[export: 'mpm_maxflow']
pub fn mpm_maxflow(input &i64, length usize) i64 {
	if unsafe { input == nil } || length < 4 || length > max_input_values { return -1 }
	unsafe {
		n_value, edge_count_value := input[0], input[1]
		source_value, sink_value := input[2], input[3]
		if n_value < 2 || n_value > max_vertices || edge_count_value < 0 ||
			edge_count_value > max_edges || source_value < 1 || source_value > n_value ||
			sink_value < 1 || sink_value > n_value || source_value == sink_value { return -1 }
		n, edge_count := int(n_value), int(edge_count_value)
		source, sink := int(source_value - 1), int(sink_value - 1)
		if length != usize(4 + 3 * edge_count) { return -1 }
		mut residual := [8][8]i64{}
		for edge in 0 .. edge_count {
			from_value, to_value, capacity := input[4 + 3 * edge], input[5 + 3 * edge], input[6 + 3 * edge]
			if from_value < 1 || from_value > n_value || to_value < 1 || to_value > n_value ||
				from_value == to_value || capacity < 0 || capacity > 100 { return -1 }
			residual[int(from_value - 1)][int(to_value - 1)] += capacity
		}
		mut total_flow := i64(0)
		for {
			mut level := [8]int{}
			for vertex in 0 .. n { level[vertex] = -1 }
			mut queue := [8]int{}
			mut head, tail := 0, 0
			level[source] = 0
			queue[tail] = source
			tail++
			for head < tail {
				vertex := queue[head]
				head++
				for next in 0 .. n {
					if residual[vertex][next] > 0 && level[next] < 0 {
						level[next] = level[vertex] + 1
						queue[tail] = next
						tail++
					}
				}
			}
			if level[sink] < 0 { break }
			mut incoming := [8]i64{}
			mut outgoing := [8]i64{}
			mut active := [8][8]bool{}
			mut alive := [8]bool{}
			for vertex in 0 .. n { alive[vertex] = level[vertex] >= 0 && level[vertex] <= level[sink] }
			for from in 0 .. n {
				for to in 0 .. n {
					if level[from] >= 0 && level[from] < level[sink] &&
						level[to] == level[from] + 1 && residual[from][to] > 0 {
						active[from][to] = true
						outgoing[from] += residual[from][to]
						incoming[to] += residual[from][to]
					}
				}
			}
			incoming[source] = flow_infinity
			outgoing[sink] = flow_infinity
			for {
				reference := -1
				mut least_potential := flow_infinity + 1
				for vertex in 0 .. n {
					if !alive[vertex] { continue }
					potential := minimum(incoming[vertex], outgoing[vertex])
					if potential < least_potential { least_potential = potential; reference = vertex }
				}
				if reference < 0 { break }
				if least_potential > 0 {
					total_flow += least_potential
					_ = push_backward(reference, source, least_potential, n, mut residual, mut active, mut incoming, mut outgoing)
					_ = push_forward(reference, sink, least_potential, n, mut residual, mut active, mut incoming, mut outgoing)
				}
				remove_vertex(reference, n, residual, mut active, mut incoming, mut outgoing, mut alive)
			}
		}
		return total_flow
	}
}
