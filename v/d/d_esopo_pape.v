const max_vertices = 16
const max_edges = 64
const max_input_length = 3 + 3 * max_edges

fn store_i64_le(output &u8, offset int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8((bits >> (byte * 8)) & 255) }
	}
}

@[export: 'd_esopo_pape']
pub fn d_esopo_pape(values &i64, length usize, output &u8, output_capacity usize) i64 {
	unsafe {
		if values == nil || length < 3 || length > usize(max_input_length) { return -1 }
		raw_n, raw_m, raw_source := values[0], values[1], values[2]
		if raw_n < 1 || raw_n > max_vertices || raw_m < 0 || raw_m > max_edges ||
			raw_source < 0 || raw_source >= raw_n || length != usize(3 + 3 * raw_m) { return -1 }
		n, m := int(raw_n), int(raw_m)

		mut head := [max_vertices]int{init: -1}
		mut to := [max_edges]int{init: 0}
		mut next := [max_edges]int{init: -1}
		mut weight := [max_edges]i64{init: 0}
		for edge := 0; edge < m; edge++ {
			u, v, w := values[3 + 3 * edge], values[4 + 3 * edge], values[5 + 3 * edge]
			if u < 0 || u >= raw_n || v < 0 || v >= raw_n || w < 0 || w > 1000 { return -1 }
			to[edge], weight[edge] = int(v), w
			next[edge] = head[int(u)]
			head[int(u)] = edge
		}

		mut distance := [max_vertices]i64{init: 0}
		mut reachable := [max_vertices]bool{init: false}
		mut queued := [max_vertices]bool{init: false}
		mut removed_before := [max_vertices]bool{init: false}
		mut deque := [max_vertices]int{init: 0}
		mut front, size := 0, 1
		source := int(raw_source)
		deque[0] = source
		distance[source] = 0
		reachable[source], queued[source] = true, true
		for size > 0 {
			vertex := deque[front]
			front = (front + 1) % n
			size--
			queued[vertex], removed_before[vertex] = false, true
			mut edge := head[vertex]
			for edge >= 0 {
				neighbor := to[edge]
				candidate := distance[vertex] + weight[edge]
				if !reachable[neighbor] || candidate < distance[neighbor] {
					distance[neighbor], reachable[neighbor] = candidate, true
					if !queued[neighbor] {
						if removed_before[neighbor] {
							front = (front + n - 1) % n
							deque[front] = neighbor
						} else {
							deque[(front + size) % n] = neighbor
						}
						size++
						queued[neighbor] = true
					}
				}
				edge = next[edge]
			}
		}

		byte_count := 8 * n
		if output == nil || output_capacity < usize(byte_count) { return -2 }
		for vertex := 0; vertex < n; vertex++ {
			result := i64(-1)
			if reachable[vertex] { result = distance[vertex] }
			store_i64_le(output, 8 * vertex, result)
		}
		return i64(byte_count)
	}
}
