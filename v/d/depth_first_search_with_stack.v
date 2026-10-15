module depth_first_search_with_stack

// Stack-based DFS that marks vertices when they are pushed, matching the source order.
@[export: 'depth_first_search_with_stack']
pub fn depth_first_search_with_stack(values &i64, length usize, output &u8, output_capacity usize) i64 {
    if length < 2 || length > 66 || (length - 2) % 2 != 0 { return -2 }
    unsafe {
        if values[0] < 0 || values[0] > 64 { return -2 }
        vertices := usize(values[0])
        start_value := values[1]
        if vertices == 0 {
            if start_value == -1 && length == 2 { return 0 }
            return -2
        }
        if start_value < 0 || u64(start_value) >= u64(vertices) { return -2 }

        mut adjacency := [2048]usize{init: 0}
        mut degree := [64]usize{init: 0}
        mut state := [64]u8{init: 0}
        edge_count := (length - 2) / 2
        for edge := usize(0); edge < edge_count; edge++ {
            origin_value := values[2 + 2 * edge]
            destination_value := values[3 + 2 * edge]
            if origin_value < 0 || destination_value < 0 ||
                u64(origin_value) >= u64(vertices) || u64(destination_value) >= u64(vertices) {
                return -2
            }
            origin := usize(origin_value)
            adjacency[origin * 32 + degree[origin]] = usize(destination_value)
            degree[origin]++
        }

        mut stack := [33]usize{init: 0}
        mut order := [64]usize{init: 0}
        mut stack_length := usize(1)
        mut count := usize(0)
        start := usize(start_value)
        state[start] = 1
        stack[0] = start
        for stack_length != 0 {
            stack_length--
            vertex := stack[stack_length]
            if state[vertex] != 1 { continue }
            order[count] = vertex
            count++
            for edge := usize(0); edge < degree[vertex]; edge++ {
                neighbor := adjacency[vertex * 32 + edge]
                stack[stack_length] = neighbor
                stack_length++
                if state[neighbor] != 2 { state[neighbor] = 1 }
            }
            state[vertex] = 2
        }
        if output_capacity < count { return -2 }
        for index := usize(0); index < count; index++ {
            output[index] = u8(order[index])
        }
        return i64(count)
    }
}
