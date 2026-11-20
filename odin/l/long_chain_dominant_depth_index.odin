package long_chain_dominant_depth_index
import "core:c"

Lc_State :: struct {
    parent: [64]int,
    first_child: [64]int,
    next_sibling: [64]int,
    height: [64]int,
    heavy: [64]int,
    base: [64]int,
    count: [64]int,
    dominant_depth: [64]int,
}

solve :: proc(state: ^Lc_State, n: int) {
    for vertex in 0..<n {
        state.first_child[vertex] = -1
        state.heavy[vertex] = -1
        state.height[vertex] = 1
    }
    state.parent[0] = -1
    for vertex in 1..<n {
        parent := state.parent[vertex]
        state.next_sibling[vertex] = state.first_child[parent]
        state.first_child[parent] = vertex
    }

    for reverse in 0..<n {
        vertex := n - 1 - reverse
        child := state.first_child[vertex]
        maximum_height := 0
        for child >= 0 {
            child_height := state.height[child]
            if child_height > maximum_height || (child_height == maximum_height && child < state.heavy[vertex]) {
                maximum_height = child_height
                state.heavy[vertex] = child
            }
            child = state.next_sibling[child]
        }
        state.height[vertex] = maximum_height + 1
    }

    pool_size := 0
    for vertex in 0..<n {
        if vertex == 0 || state.heavy[state.parent[vertex]] != vertex {
            current := vertex
            for current >= 0 {
                state.base[current] = pool_size
                pool_size += 1
                current = state.heavy[current]
            }
        }
    }

    for reverse in 0..<n {
        vertex := n - 1 - reverse
        base := state.base[vertex]
        state.count[base] = 1
        best_depth := 0
        best_count := 1
        heavy := state.heavy[vertex]
        if heavy >= 0 {
            best_depth = state.dominant_depth[heavy] + 1
            best_count = state.count[base + best_depth]
        }
        for child := state.first_child[vertex]; child >= 0; child = state.next_sibling[child] {
            if child == heavy do continue
            for child_depth in 0..<state.height[child] {
                depth := child_depth + 1
                slot := base + depth
                amount := state.count[slot] + state.count[state.base[child] + child_depth]
                state.count[slot] = amount
                if amount > best_count || (amount == best_count && depth < best_depth) {
                    best_count = amount
                    best_depth = depth
                }
            }
        }
        state.dominant_depth[vertex] = best_depth
    }
}

@(export)
long_chain_dominant_depth_index :: proc "c" (input: [^]i64, length: c.size_t,
    output: [^]u8, output_capacity: c.size_t) -> i64 {
    if input == nil || length == 0 || length > 65 do return -1
    n_value := input[0]
    if n_value < 1 || n_value > 64 || length != c.size_t(n_value) do return -1
    n := int(n_value)
    for vertex in 1..<n {
        if input[vertex] < 0 || input[vertex] >= i64(vertex) do return -1
    }
    required := 8*n
    if output == nil || output_capacity < c.size_t(required) do return -2

    state: Lc_State = {}
    for vertex in 1..<n do state.parent[vertex] = int(input[vertex])
    solve(&state, n)
    for vertex in 0..<n {
        bits := u64(state.dominant_depth[vertex])
        for byte in 0..<8 do output[8*vertex+byte] = u8(bits >> (8*byte))
    }
    return i64(required)
}
