package astar_rust_directed_graph

import "core:c"

put_i64_le :: proc "contextless" (output: [^]u8, offset: usize, value: i64) {
	bits := u64(value)
	for byte: u32 = 0; byte < 8; byte += 1 { output[offset+usize(byte)] = u8(bits >> (8*byte)) }
}

@(export)
astar_rust_directed_graph :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 4 do return -1
	vertices, edge_count := input[0], input[1]
	if vertices < 1 || vertices > 32 || edge_count < 0 || edge_count > 128 do return -1
	if length != c.size_t(4+vertices+3*edge_count) do return -1
	start, goal := input[2], input[3]
	if start < 0 || start >= vertices || goal < 0 || goal >= vertices do return -1
	for v: i64 = 0; v < vertices; v += 1 { if input[4+v] < 0 || input[4+v] > 1_000_000 do return -1 }
	if input[4+goal] != 0 do return -1
	edge_base := 4+usize(vertices)
	for e: usize = 0; e < usize(edge_count); e += 1 {
		from,to,weight := input[edge_base+3*e],input[edge_base+3*e+1],input[edge_base+3*e+2]
		if from < 0 || from >= vertices || to < 0 || to >= vertices || weight < 0 || weight > 1_000_000 || input[4+from] > weight+input[4+to] do return -1
	}
	var distance: [32]i64
	var parent: [32]i64
	var closed: [32]bool
	for v: usize = 0; v < usize(vertices); v += 1 { distance[v]=0x7fffffffffffffff; parent[v]=-1 }
	distance[start]=0
	for step: i64 = 0; step < vertices; step += 1 {
		current: i64 = -1
		for v: i64 = 0; v < vertices; v += 1 {
			if closed[v] || distance[v] == 0x7fffffffffffffff do continue
			if current < 0 || distance[v]+input[4+v] < distance[current]+input[4+current] ||
				(distance[v]+input[4+v] == distance[current]+input[4+current] && (distance[v] < distance[current] || (distance[v] == distance[current] && v < current))) do current=v
		}
		if current < 0 || current == goal do break
		closed[current]=true
		for e: usize = 0; e < usize(edge_count); e += 1 {
			if input[edge_base+3*e] != current do continue
			next:=input[edge_base+3*e+1];candidate:=distance[current]+input[edge_base+3*e+2]
			if !closed[next] && candidate < distance[next] { distance[next]=candidate;parent[next]=current }
		}
	}
	if distance[goal] == 0x7fffffffffffffff do return 0
	var reversed: [32]i64
	path_length: i64=0;current:=goal
	for path_length < vertices {
		reversed[path_length]=current;path_length+=1
		if current==start do break
		current=parent[current];if current<0 do return -1
	}
	if reversed[path_length-1]!=start do return -1
	required:=usize(8*(path_length+2))
	if output==nil || capacity<c.size_t(required) do return -2
	put_i64_le(output,0,distance[goal]);put_i64_le(output,8,path_length)
	for i:i64=0;i<path_length;i+=1 { put_i64_le(output,16+usize(i)*8,reversed[path_length-1-i]) }
	return i64(required)
}
