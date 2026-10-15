module zero_one_bfs

// 0-1 BFS over a bounded directed graph encoded as weighted edge triples.
@[export: 'zero_one_bfs']
pub fn zero_one_bfs(values &i64, length usize, output &u8, output_capacity usize) i64 {
    if length < 3 || length > 3075 { return -1 }
    unsafe {
        if values[0] < 1 || values[0] > 64 || values[2] < 0 || values[2] > 1024 { return -1 }
        vertices := usize(values[0])
        source_value := values[1]
        edge_count := usize(values[2])
        if source_value < 0 || u64(source_value) >= u64(vertices) || length != 3 + 3 * edge_count {
            return -1
        }
        source := usize(source_value)

        mut zero_edges := [64]u64{}
        mut one_edges := [64]u64{}
        mut distance := [64]u8{}
        mut deque := [4097]u8{}
        for vertex := usize(0); vertex < 64; vertex++ {
            distance[vertex] = 255
        }
        for edge := usize(0); edge < edge_count; edge++ {
            origin_value := values[3 + 3 * edge]
            destination_value := values[4 + 3 * edge]
            weight := values[5 + 3 * edge]
            if origin_value < 0 || destination_value < 0 ||
                u64(origin_value) >= u64(vertices) || u64(destination_value) >= u64(vertices) ||
                (weight != 0 && weight != 1) {
                return -1
            }
            origin := usize(origin_value)
            destination := usize(destination_value)
            mask := u64(1) << destination
            if weight == 0 { zero_edges[origin] |= mask }
            else { one_edges[origin] |= mask }
        }
        if output_capacity < vertices { return -2 }

        mut head := usize(0)
        mut tail := usize(1)
        mut queued := usize(1)
        deque[0] = u8(source)
        distance[source] = 0
        for queued != 0 {
            origin := usize(deque[head])
            head = (head + 1) % 4097
            queued--
            base := distance[origin]
            for destination := usize(0); destination < vertices; destination++ {
                mask := u64(1) << destination
                if (zero_edges[origin] & mask) != 0 && base < distance[destination] {
                    distance[destination] = base
                    if head == 0 { head = 4096 }
                    else { head-- }
                    deque[head] = u8(destination)
                    queued++
                }
                candidate := base + 1
                if (one_edges[origin] & mask) != 0 && candidate < distance[destination] {
                    distance[destination] = candidate
                    deque[tail] = u8(destination)
                    tail = (tail + 1) % 4097
                    queued++
                }
            }
        }

        for vertex := usize(0); vertex < vertices; vertex++ {
            output[vertex] = distance[vertex]
        }
        return i64(vertices)
    }
}
