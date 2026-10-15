module topological_sort_dfs

// Deterministic depth-first topological sort with three-color cycle detection.
@[export: 'topological_sort_dfs']
pub fn topological_sort_dfs(values &i64, length usize, output &u8, output_capacity usize) i64 {
    if length == 0 || length > 66 || (length - 1) % 2 != 0 { return -2 }
    unsafe {
        if values[0] < 0 || values[0] > 40 { return -2 }
        vertices := usize(values[0])
        edge_count := (length - 1) / 2
        mut adjacency := [40]u64{}
        mut state := [40]u8{}
        mut stack := [40]usize{}
        mut next_neighbor := [40]usize{}
        mut order := [40]usize{}

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

        mut count := usize(0)
        for root := usize(0); root < vertices; root++ {
            if state[root] != 0 { continue }
            mut top := usize(0)
            stack[top] = root
            next_neighbor[top] = 0
            state[root] = 1
            for {
                origin := stack[top]
                mut destination := next_neighbor[top]
                for destination < vertices && (adjacency[origin] & (u64(1) << destination)) == 0 {
                    destination++
                }
                if destination == vertices {
                    state[origin] = 2
                    order[count] = origin
                    count++
                    if top == 0 { break }
                    top--
                    continue
                }
                next_neighbor[top] = destination + 1
                if state[destination] == 1 { return -1 }
                if state[destination] == 0 {
                    top++
                    stack[top] = destination
                    next_neighbor[top] = 0
                    state[destination] = 1
                }
            }
        }

        if output_capacity < vertices { return -2 }
        for index := usize(0); index < count; index++ {
            output[index] = u8(order[count - 1 - index])
        }
        return i64(count)
    }
}
