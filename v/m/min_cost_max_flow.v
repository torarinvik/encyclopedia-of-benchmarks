// Based on AtCoder Library mcf_graph::flow (CC0 1.0); see benchmarks/m/min_cost_max_flow/LICENSE.txt.
module min_cost_max_flow

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

@[export: 'min_cost_max_flow']
pub fn min_cost_max_flow(input &i64, input_length usize, mut output &u8, output_capacity usize) i64 {
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
		mut edges := [32]Edge{}
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
		mut potential := [8]i64{}
		mut total_flow := i64(0)
		mut total_cost := i64(0)
		for total_flow < flow_limit {
			mut dist := [8]i64{}
			mut parent := [8]int{}
			mut used := [8]bool{}
			for i in 0 .. n { dist[i] = inf; parent[i] = -1; used[i] = false }
			dist[source] = 0
			for _ in 0 .. n {
				mut chosen := -1
				for vertex in 0 .. n {
					if !used[vertex] && dist[vertex] != inf && (chosen < 0 || dist[vertex] < dist[chosen]) { chosen = vertex }
				}
				if chosen < 0 { break }
				used[chosen] = true
				for e in 0 .. 2*m {
					if edges[e].from_vertex != chosen || edges[e].capacity <= 0 { continue }
					v := edges[e].to_vertex
					candidate := dist[chosen] + edges[e].cost + potential[chosen] - potential[v]
					if !used[v] && candidate < dist[v] { dist[v] = candidate; parent[v] = e }
				}
			}
			if dist[sink] == inf { break }
			for vertex in 0 .. n { if dist[vertex] != inf { potential[vertex] += dist[vertex] } }
			mut amount := flow_limit - total_flow
			mut vertex := sink
			for vertex != source {
				e := parent[vertex]
				if e < 0 { return -1 }
				if amount > edges[e].capacity { amount = edges[e].capacity }
				vertex = edges[e].from_vertex
			}
			vertex = sink
			for vertex != source {
				e := parent[vertex]
				edges[e].capacity -= amount
				edges[edges[e].reverse_index].capacity += amount
				vertex = edges[e].from_vertex
			}
			total_flow += amount
			total_cost += amount * (potential[sink] - potential[source])
		}
		flow_bits := u64(total_flow)
		cost_bits := u64(total_cost)
		for i in 0 .. 8 { output[i] = u8(flow_bits >> (8*i)); output[8+i] = u8(cost_bits >> (8*i)) }
		return 16
	}
}
