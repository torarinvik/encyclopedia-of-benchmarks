module topological_sort

// Kahn topological sort over a bounded directed graph encoded as edge pairs.
@[export: 'topological_sort']
pub fn topological_sort(values &i64, length usize, output &u8, output_capacity usize) i64 {
    if length == 0 || length > 66 || (length - 1) % 2 != 0 { return -2 }
    unsafe {
        if values[0] < 0 || values[0] > 64 { return -2 }
        vertices := usize(values[0])
        edge_count := (length - 1) / 2
        mut adjacency := [64]u64{}
        mut indegree := [64]usize{}
        mut queue := [64]usize{}
        mut order := [64]usize{}

        for edge := usize(0); edge < edge_count; edge++ {
            origin_value := values[1 + 2 * edge]
            destination_value := values[2 + 2 * edge]
            if origin_value < 0 || destination_value < 0 ||
                u64(origin_value) >= u64(vertices) || u64(destination_value) >= u64(vertices) {
                return -2
            }
            origin := usize(origin_value)
            destination := usize(destination_value)
            mask := u64(1) << destination
            if adjacency[origin] & mask == 0 {
                adjacency[origin] |= mask
                indegree[destination]++
            }
        }
        mut head := usize(0)
        mut tail := usize(0)
        for vertex := usize(0); vertex < vertices; vertex++ {
            if indegree[vertex] == 0 {
                queue[tail] = vertex
                tail++
            }
        }
        mut count := usize(0)
        for head < tail {
            origin := queue[head]
            head++
            order[count] = origin
            count++
            for destination := usize(0); destination < vertices; destination++ {
                if adjacency[origin] & (u64(1) << destination) != 0 {
                    indegree[destination]--
                    if indegree[destination] == 0 {
                        queue[tail] = destination
                        tail++
                    }
                }
            }
        }
        if count != vertices { return -1 }
        if output_capacity < vertices { return -2 }
        for index := usize(0); index < count; index++ {
            output[index] = u8(order[index])
        }
        return i64(count)
    }
}
