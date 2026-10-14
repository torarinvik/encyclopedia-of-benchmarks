module breadth_first_search

// Traverse a directed graph from start with fixed-size adjacency bitsets.
@[export: 'breadth_first_search']
pub fn breadth_first_search(values &i64, length usize, output &u8, output_capacity usize) i64 {
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
        mut adjacency := [64]u64{init: 0}
        mut visited := [64]bool{init: false}
        mut order := [64]usize{init: 0}
        edge_count := (length - 2) / 2
        for edge := usize(0); edge < edge_count; edge++ {
            origin_value := values[2 + 2 * edge]
            destination_value := values[3 + 2 * edge]
            if origin_value < 0 || destination_value < 0 ||
                u64(origin_value) >= u64(vertices) || u64(destination_value) >= u64(vertices) {
                return -2
            }
            origin := usize(origin_value)
            destination := usize(destination_value)
            adjacency[origin] |= u64(1) << destination
        }
        start := usize(start_value)
        mut count := usize(0)
        visited[start] = true
        mut queue := [64]usize{init: 0}
        mut head := usize(0)
        mut tail := usize(1)
        queue[0] = start
        for head < tail {
            origin := queue[head]
            head++
            order[count] = origin
            count++
            for destination := usize(0); destination < vertices; destination++ {
                if adjacency[origin] & (u64(1) << destination) != 0 && !visited[destination] {
                    visited[destination] = true
                    queue[tail] = destination
                    tail++
                }
            }
        }
        if output_capacity < count { return -2 }
        for index := usize(0); index < count; index++ {
            output[index] = u8(order[index])
        }
        return i64(count)
    }
}
