// Clean-room shortest-path tight-edge blocking-flow method; see package RIGHTS.md.
module min_cost_max_flow_blocking_paths

const max_n = 8
const max_m = 16
const max_input = 69
const inf = i64(1) << 60

struct Edge {
	from_vertex int
	to_vertex int
	reverse_index int
	capacity i64
	cost i64
}

fn send_tight_level_flow(u int, sink int, limit i64, mut edges []Edge,
	arc_count int, dist []i64, level []int, mut current []int) i64 {
	if u == sink { return limit }
	for current[u] < arc_count {
		e := current[u]
		if edges[e].from_vertex != u || edges[e].capacity <= 0 { current[u]++; continue }
		v := edges[e].to_vertex
		if dist[v] == inf || dist[v] != dist[u] + edges[e].cost || level[v] != level[u] + 1 { current[u]++; continue }
		amount := min(limit, edges[e].capacity)
		sent := send_tight_level_flow(v, sink, amount, mut edges, arc_count, dist, level, mut current)
		if sent > 0 {
			reverse := edges[e].reverse_index
			edges[e].capacity -= sent
			edges[reverse].capacity += sent
			if edges[e].capacity == 0 { current[u]++ }
			return sent
		}
		current[u]++
	}
	return 0
}

@[export: 'min_cost_max_flow_blocking_paths']
pub fn min_cost_max_flow_blocking_paths(input &i64, input_length usize, mut output &u8, output_capacity usize) i64 {
	unsafe {
		if input == nil || input_length < 5 || input_length > max_input { return -1 }
		n_value := input[0]
		m_value := input[1]
		source_value := input[2]
		sink_value := input[3]
		flow_limit := input[4]
		if n_value < 2 || n_value > max_n || m_value < 0 || m_value > max_m || input_length != usize(5 + 4*m_value) { return -1 }
		if source_value < 0 || source_value >= n_value || sink_value < 0 || sink_value >= n_value || source_value == sink_value || flow_limit < 0 || flow_limit > 16 { return -1 }
		n := int(n_value)
		m := int(m_value)
		source := int(source_value)
		sink := int(sink_value)
		mut edges := []Edge{len: 32}
		for i in 0 .. m {
			u := input[5+4*i]
			v := input[6+4*i]
			cap := input[7+4*i]
			cost := input[8+4*i]
			if u < 0 || u >= n_value || v < 0 || v >= n_value || cap < 0 || cap > 5 || cost < 0 || cost > 20 { return -1 }
			e := 2*i
			edges[e] = Edge{from_vertex: int(u), to_vertex: int(v), reverse_index: e+1, capacity: cap, cost: cost}
			edges[e+1] = Edge{from_vertex: int(v), to_vertex: int(u), reverse_index: e, capacity: 0, cost: -cost}
		}
		if output == nil || output_capacity < 16 { return -2 }
		mut total_flow := i64(0)
		mut total_cost := i64(0)
		for total_flow < flow_limit {
			mut dist := []i64{len: 8, init: inf}
			mut queue := []int{len: 8, init: 0}
			mut in_queue := []bool{len: 8, init: false}
			dist[source] = 0
			mut head := 0
			mut tail := 0
			mut queued := 0
			queue[tail] = source
			tail = (tail+1)%n
			queued++
			in_queue[source] = true
			for queued > 0 {
				u := queue[head]
				head = (head+1)%n
				queued--
				in_queue[u] = false
				for e in 0 .. 2*m {
					if edges[e].from_vertex != u || edges[e].capacity <= 0 { continue }
					v := edges[e].to_vertex
					candidate := dist[u] + edges[e].cost
					if candidate < dist[v] {
						dist[v] = candidate
						if !in_queue[v] { queue[tail] = v; tail = (tail+1)%n; queued++; in_queue[v] = true }
					}
				}
			}
			if dist[sink] == inf { break }
			for total_flow < flow_limit {
				mut level := []int{len: 8, init: -1}
				mut breadth := []int{len: 8, init: 0}
				mut current := []int{len: 8, init: 0}
				mut first := 0
				mut last := 0
				level[source] = 0
				breadth[last] = source
				last++
				for first < last {
					u := breadth[first]
					first++
					for e in 0 .. 2*m {
						if edges[e].from_vertex != u || edges[e].capacity <= 0 { continue }
						v := edges[e].to_vertex
						if dist[v] == dist[u]+edges[e].cost && level[v] < 0 { level[v] = level[u]+1; breadth[last] = v; last++ }
					}
				}
				if level[sink] < 0 { break }
				amount := send_tight_level_flow(source, sink, flow_limit-total_flow, mut edges, 2*m, dist, level, mut current)
				if amount == 0 { break }
				total_flow += amount
				total_cost += amount * dist[sink]
			}
		}
		flow_bits := u64(total_flow)
		cost_bits := u64(total_cost)
		for i in 0 .. 8 { output[i] = u8(flow_bits >> (8*i)); output[8+i] = u8(cost_bits >> (8*i)) }
		return 16
	}
}
