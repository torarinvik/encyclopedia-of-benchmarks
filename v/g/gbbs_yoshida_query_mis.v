// Clean-room GBBS Yoshida recursive MIS query; see package LICENSE.txt.
fn hash64(value u64) u64 {
	mut mixed := value * u64(3935559000370003845) + u64(2691343689449507681)
	mixed = mixed ^ (mixed >> 21)
	mixed = mixed ^ (mixed << 37)
	mixed = mixed ^ (mixed >> 4)
	mixed *= u64(4768777513237032717)
	mixed = mixed ^ (mixed << 20)
	mixed = mixed ^ (mixed >> 41)
	mixed = mixed ^ (mixed << 5)
	return mixed
}

fn store_i64_le(output &u8, offset int, value i64) {
	mut bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8(bits & 255) }
		bits >>= 8
	}
}

fn query(vertex int, degree []int, neighbors [][]int, priority []u64, mut work int, cutoff int) i64 {
	for index in 0 .. degree[vertex] {
		if work == cutoff { return -1 }
		neighbor := neighbors[vertex][index]
		work++
		if priority[vertex] < priority[neighbor] ||
			(priority[vertex] == priority[neighbor] && vertex <= neighbor) { break }
		status := query(neighbor, degree, neighbors, priority, mut work, cutoff)
		if status == 1 { return 0 }
		if status == -1 { return -1 }
	}
	return 1
}

@[export: 'gbbs_yoshida_query_mis']
pub fn gbbs_yoshida_query_mis(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 4 || length > 52 { return -1 }
		n64 := input[0]
		m64 := input[1]
		root64 := input[2]
		cutoff64 := input[3]
		if n64 < 1 || n64 > 12 || m64 < 0 || m64 > 24 || root64 < 0 || root64 >= n64 ||
			cutoff64 < 0 || cutoff64 > 128 || length != usize(4 + 2 * m64) { return -1 }
		n := int(n64)
		m := int(m64)
		mut adjacent := [][]bool{len: 12, init: []bool{len: 12, init: false}}
		mut degree := []int{len: 12, init: 0}
		for edge in 0 .. m {
			u64 := input[4 + 2 * edge]
			v64 := input[5 + 2 * edge]
			if u64 < 0 || v64 <= u64 || v64 >= n64 { return -1 }
			u := int(u64)
			v := int(v64)
			if adjacent[u][v] { return -1 }
			adjacent[u][v] = true
			adjacent[v][u] = true
			degree[u]++
			degree[v]++
		}
		if output == nil || capacity < 16 { return -2 }
		mut priority := []u64{len: 12, init: 0}
		mut neighbors := [][]int{len: 12, init: []int{len: 12, init: 0}}
		for vertex in 0 .. n { priority[vertex] = hash64(u64(vertex)) }
		for vertex in 0 .. n {
			mut inserted := 0
			for other in 0 .. n {
				if adjacent[vertex][other] {
					mut position := inserted
					for position > 0 {
						previous := neighbors[vertex][position - 1]
						if priority[previous] < priority[other] ||
							(priority[previous] == priority[other] && previous < other) { break }
						neighbors[vertex][position] = previous
						position--
					}
					neighbors[vertex][position] = other
					inserted++
				}
			}
		}
		mut work := 0
		status := query(int(root64), degree, neighbors, priority, mut work, int(cutoff64))
		store_i64_le(output, 0, status)
		store_i64_le(output, 8, i64(work))
		return 16
	}
}
