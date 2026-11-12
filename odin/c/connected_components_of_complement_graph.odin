package connected_components_of_complement_graph

import "core:c"

MAX_N :: 64
MAX_M :: MAX_N * (MAX_N - 1) / 2
MAX_INPUT_VALUES :: 2 + 2 * MAX_M
MAX_OUTPUT_VALUES :: 1 + 2 * MAX_N

store_i64_le :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
    bits := u64(value)
    for byte := 0; byte < 8; byte += 1 {
        output[offset + byte] = u8(bits >> u64(8 * byte))
    }
}

@(export)
connected_components_of_complement_graph :: proc "c" (input: [^]i64,
    length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || length < 2 || length > MAX_INPUT_VALUES do return -1
    n_value := input[0]
    m_value := input[1]
    if n_value < 1 || n_value > MAX_N || m_value < 0 do return -1
    if m_value > n_value * (n_value - 1) / 2 do return -1
    n := int(n_value)
    m := int(m_value)
    if length != c.size_t(2 + 2 * m) do return -1

    graph: [MAX_N]u64
    for vertex := 0; vertex < MAX_N; vertex += 1 do graph[vertex] = 0
    for edge := 0; edge < m; edge += 1 {
        left_value := input[2 + 2 * edge]
        right_value := input[3 + 2 * edge]
        if left_value < 0 || left_value >= n_value || right_value < 0 ||
           right_value >= n_value || left_value == right_value do return -1
        left := int(left_value)
        right := int(right_value)
        bit := u64(1) << u64(right)
        if (graph[left] & bit) != 0 do return -1
        graph[left] |= bit
        graph[right] |= u64(1) << u64(left)
    }

    remaining: [MAX_N]int
    queue: [MAX_N]int
    label: [MAX_N]int
    for vertex := 0; vertex < n; vertex += 1 {
        remaining[vertex] = vertex
        label[vertex] = -1
    }
    remaining_count := n
    component_count := 0
    for remaining_count > 0 {
        remaining_count -= 1
        root := remaining[remaining_count]
        label[root] = component_count
        head := 0
        tail := 1
        queue[0] = root
        for head < tail {
            vertex := queue[head]
            head += 1
            position := 0
            for position < remaining_count {
                candidate := remaining[position]
                if ((graph[vertex] >> u64(candidate)) & 1) != 0 {
                    position += 1
                } else {
                    remaining_count -= 1
                    remaining[position] = remaining[remaining_count]
                    label[candidate] = component_count
                    queue[tail] = candidate
                    tail += 1
                }
            }
        }
        component_count += 1
    }

    staged: [MAX_OUTPUT_VALUES]i64
    used := 0
    staged[used] = i64(component_count)
    used += 1
    emitted: [MAX_N]bool
    for component := 0; component < MAX_N; component += 1 do emitted[component] = false
    for first := 0; first < n; first += 1 {
        component := label[first]
        if emitted[component] do continue
        emitted[component] = true
        component_size := 0
        for vertex := 0; vertex < n; vertex += 1 {
            if label[vertex] == component do component_size += 1
        }
        staged[used] = i64(component_size)
        used += 1
        for vertex := 0; vertex < n; vertex += 1 {
            if label[vertex] == component {
                staged[used] = i64(vertex)
                used += 1
            }
        }
    }

    required := 8 * used
    if output == nil || capacity < c.size_t(required) do return -2
    for index := 0; index < used; index += 1 {
        store_i64_le(output, 8 * index, staged[index])
    }
    return i64(required)
}
