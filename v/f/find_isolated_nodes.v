module find_isolated_nodes

@[export: 'find_isolated_nodes']
pub fn find_isolated_nodes(values &i64, length usize, output &u8, output_capacity usize) i64 {
	if length < 1 || length > 65 || (length - 1) % 2 != 0 { return -2 }
	unsafe {
		if values[0] < 0 || values[0] > 64 { return -2 }
		vertices := usize(values[0])
		mut adjacency := [64]u64{init: 0}
		edge_count := (length - 1) / 2
		for edge := usize(0); edge < edge_count; edge++ {
			origin_value := values[1 + 2 * edge]
			destination_value := values[2 + 2 * edge]
			if origin_value < 0 || destination_value < 0 ||
				u64(origin_value) >= u64(vertices) || u64(destination_value) >= u64(vertices) {
				return -2
			}
			origin := usize(origin_value)
			destination := usize(destination_value)
			adjacency[origin] |= u64(1) << destination
		}
		mut isolated := [64]u8{init: 0}
		mut count := usize(0)
		for vertex := usize(0); vertex < vertices; vertex++ {
			if adjacency[vertex] == 0 {
				isolated[count] = u8(vertex)
				count++
			}
		}
		if output_capacity < count { return -2 }
		for index := usize(0); index < count; index++ {
			output[index] = isolated[index]
		}
		return i64(count)
	}
}
