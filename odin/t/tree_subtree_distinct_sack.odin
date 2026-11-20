package tree_subtree_distinct_sack
import "core:c"

Sack_State :: struct {
    n: int,
    parent: [64]int,
    first_child: [64]int,
    next_sibling: [64]int,
    order: [64]int,
    tin: [64]int,
    subtree_size: [64]int,
    heavy: [64]int,
    frequency: [256]int,
    answer: [64]int,
    distinct: int,
    frame_vertex: [64]int,
    frame_keep: [64]bool,
    frame_stage: [64]int,
    frame_child: [64]int,
}

add_interval :: proc(state: ^Sack_State, colors: [64]int, begin, count, delta: int) {
    for position in begin..<begin+count {
        color := colors[state.order[position]]
        if delta > 0 {
            if state.frequency[color] == 0 do state.distinct += 1
            state.frequency[color] += 1
        } else {
            state.frequency[color] -= 1
            if state.frequency[color] == 0 do state.distinct -= 1
        }
    }
}

solve_sack :: proc(state: ^Sack_State, colors: [64]int) {
    stack_next: [64]int = {}
    depth, timer := 1, 1
    state.order[0] = 0
    state.tin[0] = 0
    stack_next[0] = state.first_child[0]
    for depth > 0 {
        frame := depth - 1
        child := stack_next[frame]
        if child >= 0 {
            stack_next[frame] = state.next_sibling[child]
            state.tin[child] = timer
            state.order[timer] = child
            timer += 1
            stack_next[depth] = state.first_child[child]
            depth += 1
        } else {
            depth -= 1
        }
    }

    for vertex in 0..<state.n {
        state.subtree_size[vertex] = 1
        state.heavy[vertex] = -1
    }
    for reverse in 0..<(state.n-1) {
        position := state.n - 1 - reverse
        vertex := state.order[position]
        parent := state.parent[vertex]
        state.subtree_size[parent] += state.subtree_size[vertex]
        old_heavy := state.heavy[parent]
        if old_heavy < 0 || state.subtree_size[vertex] > state.subtree_size[old_heavy] {
            state.heavy[parent] = vertex
        }
    }

    frame_count := 1
    state.frame_vertex[0] = 0
    state.frame_keep[0] = false
    state.frame_stage[0] = 0
    state.frame_child[0] = state.first_child[0]
    for frame_count > 0 {
        frame := frame_count - 1
        vertex := state.frame_vertex[frame]
        if state.frame_stage[frame] == 0 {
            child := state.frame_child[frame]
            for child >= 0 && child == state.heavy[vertex] {
                child = state.next_sibling[child]
            }
            if child >= 0 {
                state.frame_child[frame] = state.next_sibling[child]
                state.frame_vertex[frame_count] = child
                state.frame_keep[frame_count] = false
                state.frame_stage[frame_count] = 0
                state.frame_child[frame_count] = state.first_child[child]
                frame_count += 1
            } else {
                state.frame_stage[frame] = 1
            }
        } else if state.frame_stage[frame] == 1 {
            state.frame_stage[frame] = 2
            child := state.heavy[vertex]
            if child >= 0 {
                state.frame_vertex[frame_count] = child
                state.frame_keep[frame_count] = true
                state.frame_stage[frame_count] = 0
                state.frame_child[frame_count] = state.first_child[child]
                frame_count += 1
            }
        } else {
            for child := state.first_child[vertex]; child >= 0; child = state.next_sibling[child] {
                if child != state.heavy[vertex] {
                    add_interval(state, colors, state.tin[child], state.subtree_size[child], 1)
                }
            }
            color := colors[vertex]
            if state.frequency[color] == 0 do state.distinct += 1
            state.frequency[color] += 1
            state.answer[vertex] = state.distinct
            if !state.frame_keep[frame] {
                add_interval(state, colors, state.tin[vertex], state.subtree_size[vertex], -1)
            }
            frame_count -= 1
        }
    }
}

@(export)
tree_subtree_distinct_sack :: proc "c" (input: [^]i64, length: c.size_t,
    output: [^]u8, output_capacity: c.size_t) -> i64 {
    if input == nil || length < 2 || length > 130 do return -1
    n_value := input[0]
    if n_value < 1 || n_value > 64 || length != c.size_t(2*n_value) do return -1
    n := int(n_value)
    for vertex in 1..<n {
        if input[vertex] < 0 || input[vertex] >= i64(vertex) do return -1
    }
    colors: [64]int = {}
    for vertex in 0..<n {
        color := input[n+vertex]
        if color < 0 || color > 255 do return -1
        colors[vertex] = int(color)
    }
    required := 8*n
    if output == nil || output_capacity < c.size_t(required) do return -2

    state: Sack_State = {}
    state.n = n
    for vertex in 0..<n do state.first_child[vertex] = -1
    for vertex in 1..<n {
        parent := int(input[vertex])
        state.parent[vertex] = parent
        state.next_sibling[vertex] = state.first_child[parent]
        state.first_child[parent] = vertex
    }
    solve_sack(&state, colors)
    for vertex in 0..<n {
        bits := u64(state.answer[vertex])
        for byte in 0..<8 do output[8*vertex+byte] = u8(bits >> (8*byte))
    }
    return i64(required)
}
