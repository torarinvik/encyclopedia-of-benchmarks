module topological

// Source-faithful port of TheAlgorithms/Go graph.Topological.
@[export: 'topological']
pub fn topological(values &i64, length usize, output &u8, output_capacity usize) i64 {
    if length == 0 || length > 66 || (length - 1) % 2 != 0 { return -2 }
    unsafe {
        if values[0] < 0 || values[0] > 64 { return -2 }
        vertices := usize(values[0])
        edge_count := (length - 1) / 2
        mut dependencies := [64]u8{}
        mut adjacency := [64]u64{}
        mut answer := [96]u8{}

        for edge := usize(0); edge < edge_count; edge++ {
            origin_value := values[1 + 2 * edge]
            destination_value := values[2 + 2 * edge]
            if origin_value < 0 || destination_value < 0 ||
                u64(origin_value) >= u64(vertices) || u64(destination_value) >= u64(vertices) {
                return -2
            }
            origin := usize(origin_value)
            destination := usize(destination_value)
            dependencies[destination]++
            adjacency[origin] |= u64(1) << destination
        }

        mut answer_count := usize(0)
        for root := usize(0); root < vertices; root++ {
            if dependencies[root] != 0 { continue }
            mut stack := [64]usize{}
            mut top := usize(0)
            stack[top] = root
            top++
            for top > 0 {
                top--
                origin := stack[top]
                answer[answer_count] = u8(origin)
                answer_count++
                for destination := usize(0); destination < vertices; destination++ {
                    edge_mask := u64(1) << destination
                    if adjacency[origin] & edge_mask != 0 {
                        mut in_stack := false
                        for index := usize(0); index < top; index++ {
                            if stack[index] == destination {
                                in_stack = true
                                break
                            }
                        }
                        if !in_stack {
                            stack[top] = destination
                            top++
                        }
                    }
                    adjacency[origin] &= ~edge_mask
                    adjacency[destination] &= ~(u64(1) << origin)
                }
            }
        }

        if output_capacity < answer_count { return -2 }
        for index := usize(0); index < answer_count; index++ {
            output[index] = answer[index]
        }
        return i64(answer_count)
    }
}
