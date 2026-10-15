module astar_rust_directed_graph

@[export: 'astar_rust_directed_graph']
pub fn astar_rust_directed_graph(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 4 { return -1 }
	unsafe {
		vertices, edge_count := input[0], input[1]
		if vertices < 1 || vertices > 32 || edge_count < 0 || edge_count > 128 { return -1 }
		if length != usize(4 + vertices + 3 * edge_count) { return -1 }
		start, goal := input[2], input[3]
		if start < 0 || start >= vertices || goal < 0 || goal >= vertices { return -1 }
		mut heuristic := []i64{len: int(vertices)}
		for v in 0 .. int(vertices) { heuristic[v] = input[4+v]; if heuristic[v] < 0 || heuristic[v] > 1_000_000 { return -1 } }
		if heuristic[goal] != 0 { return -1 }
		edge_base := 4 + int(vertices)
		for e in 0 .. int(edge_count) {
			from,to,weight := input[edge_base+3*e],input[edge_base+3*e+1],input[edge_base+3*e+2]
			if from < 0 || from >= vertices || to < 0 || to >= vertices || weight < 0 || weight > 1_000_000 || heuristic[from] > weight+heuristic[to] { return -1 }
		}
		mut distance := []i64{len: int(vertices), init: 0x7fffffffffffffff}
		mut parent := []i64{len: int(vertices), init: -1}
		mut closed := []bool{len: int(vertices)}
		distance[start]=0
		for _ in 0 .. int(vertices) {
			mut current := i64(-1)
			for v in 0 .. int(vertices) {
				if closed[v] || distance[v] == 0x7fffffffffffffff { continue }
				if current < 0 || distance[v]+heuristic[v] < distance[current]+heuristic[current] ||
					(distance[v]+heuristic[v] == distance[current]+heuristic[current] && (distance[v] < distance[current] || (distance[v] == distance[current] && i64(v) < current))) { current=i64(v) }
			}
			if current < 0 || current == goal { break }
			closed[current]=true
			for e in 0 .. int(edge_count) {
				if input[edge_base+3*e] != current { continue }
				next:=input[edge_base+3*e+1];candidate:=distance[current]+input[edge_base+3*e+2]
				if !closed[next] && candidate < distance[next] { distance[next]=candidate;parent[next]=current }
			}
		}
		if distance[goal] == 0x7fffffffffffffff { return 0 }
		mut reversed := []i64{len: int(vertices)}; mut path_len:=0;mut current:=goal
		for path_len < int(vertices) { reversed[path_len]=current;path_len++;if current==start { break };current=parent[current];if current<0 { return -1 } }
		if reversed[path_len-1] != start { return -1 }
		required:=8*(path_len+2);if output==nil || capacity<required { return -2 }
		put_i64_le(mut output,0,distance[goal]);put_i64_le(mut output,8,i64(path_len))
		for i in 0 .. path_len { put_i64_le(mut output,16+i*8,reversed[path_len-1-i]) }
		return i64(required)
	}
}

fn put_i64_le(mut output &u8, offset int, value i64) {
	bits:=u64(value)
	for byte in 0 .. 8 { unsafe { output[offset+byte]=u8(bits>>(8*byte)) } }
}
