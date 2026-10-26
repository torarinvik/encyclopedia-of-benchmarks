// Clean-room negative-cycle detection and witness extraction.
@[export: 'negative_cycle_detection']
pub fn negative_cycle_detection(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > 194 { return -1 }
		n64 := input[0]
		m64 := input[1]
		if n64 < 0 || n64 > 20 || m64 < 0 || m64 > 64 { return -1 }
		n := int(n64)
		m := int(m64)
		if length != usize(2 + 3*m) { return -1 }
		mut edge_from := []int{len: 64, init: 0}
		mut edge_to := []int{len: 64, init: 0}
		mut weight := []i64{len: 64, init: 0}
		for edge in 0 .. m {
			u64 := input[2 + 3*edge]
			v64 := input[3 + 3*edge]
			w := input[4 + 3*edge]
			if u64 < 0 || u64 >= n64 || v64 < 0 || v64 >= n64 || w < -1000 || w > 1000 { return -1 }
			edge_from[edge] = int(u64)
			edge_to[edge] = int(v64)
			weight[edge] = w
		}
		mut distance := []i64{len: 20, init: 0}
		mut predecessor := []int{len: 20, init: -1}
		mut changed_vertex := -1
		for _pass in 0 .. n {
			changed_vertex = -1
			for edge in 0 .. m {
				u := edge_from[edge]
				v := edge_to[edge]
				candidate := distance[u] + weight[edge]
				if candidate < distance[v] { distance[v] = candidate; predecessor[v] = u; changed_vertex = v }
			}
			if changed_vertex < 0 { break }
		}
		mut record := []i64{len: 22, init: 0}
		mut record_length := 1
		if changed_vertex >= 0 {
			mut vertex := changed_vertex
			for _step in 0 .. n {
				if predecessor[vertex] < 0 { return -1 }
				vertex = predecessor[vertex]
			}
			start := vertex
			mut cycle := []int{len: 20, init: 0}
			mut cycle_length := 0
			for {
				if cycle_length >= n || predecessor[vertex] < 0 { return -1 }
				cycle[cycle_length] = vertex
				cycle_length++
				vertex = predecessor[vertex]
				if vertex == start { break }
			}
			for left in 0 .. cycle_length / 2 {
				right := cycle_length - 1 - left
				temporary := cycle[left]
				cycle[left] = cycle[right]
				cycle[right] = temporary
			}
			mut minimum := 0
			for i in 1 .. cycle_length { if cycle[i] < cycle[minimum] { minimum = i } }
			record[0] = 1
			record[1] = i64(cycle_length)
			for i in 0 .. cycle_length { record[2+i] = i64(cycle[(minimum+i)%cycle_length]) }
			record_length = cycle_length + 2
		} else { record[0] = 0 }
		output_length := 8 * record_length
		if output == nil || capacity < usize(output_length) { return -2 }
		for i in 0 .. record_length {
			bits := u64(record[i])
			for byte in 0 .. 8 { output[8*i+byte] = u8((bits >> (8*byte)) & 255) }
		}
		return i64(output_length)
	}
}
