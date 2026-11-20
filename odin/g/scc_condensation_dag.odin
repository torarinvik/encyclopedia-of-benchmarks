// Clean-room bounded Kosaraju plus condensation quotient construction.
package scc_condensation_dag

import "core:c"

MAX_N :: 8
MAX_M :: 28
MAX_INPUT :: 58
MAX_OUTPUT :: 17

@(export)
scc_condensation_dag :: proc "c" (input: [^]i64, length: c.size_t,
    output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || length < 2 || length > MAX_INPUT do return -1
    n64, m64 := input[0], input[1]
    if n64 < 0 || n64 > MAX_N || m64 < 0 || m64 > MAX_M do return -1
    n, m := int(n64), int(m64)
    if length != c.size_t(2+2*m) do return -1
    adjacency: [MAX_N]u16
    reverse: [MAX_N]u16
    for edge := 0; edge < m; edge += 1 {
        source, target := input[2+2*edge], input[3+2*edge]
        if source < 0 || source >= n64 || target < 0 || target >= n64 do return -1
        adjacency[int(source)] |= u16(1) << u16(target)
        reverse[int(target)] |= u16(1) << u16(source)
    }

    visited: [MAX_N]bool
    order: [MAX_N]int
    stack_vertex: [MAX_N]int
    stack_next: [MAX_N]int
    order_count := 0
    for start := 0; start < n; start += 1 {
        if visited[start] do continue
        stack_size := 1
        stack_vertex[0], stack_next[0] = start, 0
        visited[start] = true
        for stack_size > 0 {
            frame := stack_size - 1
            vertex := stack_vertex[frame]
            candidate := stack_next[frame]
            for candidate < n && (adjacency[vertex] & (u16(1) << u16(candidate))) == 0 do candidate += 1
            if candidate < n {
                stack_next[frame] = candidate + 1
                if !visited[candidate] {
                    visited[candidate] = true
                    stack_vertex[stack_size], stack_next[stack_size] = candidate, 0
                    stack_size += 1
                }
            } else {
                order[order_count] = vertex
                order_count += 1
                stack_size -= 1
            }
        }
    }

    raw_component: [MAX_N]int
    for vertex := 0; vertex < n; vertex += 1 {
        raw_component[vertex] = -1
        visited[vertex] = false
    }
    component_count := 0
    for order_count > 0 {
        order_count -= 1
        start := order[order_count]
        if visited[start] do continue
        stack_size := 1
        stack_vertex[0] = start
        visited[start] = true
        raw_component[start] = component_count
        for stack_size > 0 {
            stack_size -= 1
            vertex := stack_vertex[stack_size]
            for next := 0; next < n; next += 1 {
                if (reverse[vertex] & (u16(1) << u16(next))) != 0 && !visited[next] {
                    visited[next] = true
                    raw_component[next] = component_count
                    stack_vertex[stack_size] = next
                    stack_size += 1
                }
            }
        }
        component_count += 1
    }

    minimum: [MAX_N]int
    raw_order: [MAX_N]int
    canonical: [MAX_N]int
    labels: [MAX_N]int
    row_mask: [MAX_N]u8
    for component := 0; component < component_count; component += 1 {
        minimum[component] = n
        raw_order[component] = component
    }
    for vertex := 0; vertex < n; vertex += 1 {
        component := raw_component[vertex]
        if vertex < minimum[component] do minimum[component] = vertex
    }
    for i := 1; i < component_count; i += 1 {
        key := raw_order[i]
        j := i
        for j > 0 && minimum[raw_order[j-1]] > minimum[key] {
            raw_order[j] = raw_order[j-1]
            j -= 1
        }
        raw_order[j] = key
    }
    for i := 0; i < component_count; i += 1 { canonical[raw_order[i]] = i }
    for vertex := 0; vertex < n; vertex += 1 { labels[vertex] = canonical[raw_component[vertex]] }
    for source := 0; source < n; source += 1 {
        for target := 0; target < n; target += 1 {
            if (adjacency[source] & (u16(1) << u16(target))) == 0 do continue
            left, right := labels[source], labels[target]
            if left != right do row_mask[left] |= u8(1) << u8(right)
        }
    }

    output_size := 1+n+component_count
    if output == nil || capacity < c.size_t(output_size) do return -2
    staged: [MAX_OUTPUT]u8
    staged[0] = u8(component_count)
    for vertex := 0; vertex < n; vertex += 1 { staged[1+vertex] = u8(labels[vertex]) }
    for component := 0; component < component_count; component += 1 { staged[1+n+component] = row_mask[component] }
    for index := 0; index < output_size; index += 1 { output[index] = staged[index] }
    return i64(output_size)
}
