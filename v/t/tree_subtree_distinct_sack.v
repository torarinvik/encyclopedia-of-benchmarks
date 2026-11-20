module tree_subtree_distinct_sack

struct SackState {
    n int
    parent [64]int
    first_child [64]int
    next_sibling [64]int
    order [64]int
    tin [64]int
    subtree_size [64]int
    heavy [64]int
    frequency [256]int
    answer [64]int
    distinct int
    frame_vertex [64]int
    frame_keep [64]bool
    frame_stage [64]int
    frame_child [64]int
}

fn add_interval(mut state SackState, colors [64]int, begin int, count int, delta int) {
    for offset in 0 .. count {
        color := colors[state.order[begin + offset]]
        if delta > 0 {
            if state.frequency[color] == 0 { state.distinct++ }
            state.frequency[color]++
        } else {
            state.frequency[color]--
            if state.frequency[color] == 0 { state.distinct-- }
        }
    }
}

fn solve_sack(mut state SackState, colors [64]int) {
    mut stack_next := [64]int{}
    mut depth := 1
    mut timer := 1
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
            timer++
            stack_next[depth] = state.first_child[child]
            depth++
        } else {
            depth--
        }
    }

    for vertex in 0 .. state.n {
        state.subtree_size[vertex] = 1
        state.heavy[vertex] = -1
    }
    for reverse in 0 .. (state.n - 1) {
        position := state.n - 1 - reverse
        vertex := state.order[position]
        parent := state.parent[vertex]
        state.subtree_size[parent] += state.subtree_size[vertex]
        old_heavy := state.heavy[parent]
        if old_heavy < 0 || state.subtree_size[vertex] > state.subtree_size[old_heavy] {
            state.heavy[parent] = vertex
        }
    }

    mut frame_count := 1
    state.frame_vertex[0] = 0
    state.frame_keep[0] = false
    state.frame_stage[0] = 0
    state.frame_child[0] = state.first_child[0]
    for frame_count > 0 {
        frame := frame_count - 1
        vertex := state.frame_vertex[frame]
        if state.frame_stage[frame] == 0 {
            mut child := state.frame_child[frame]
            for child >= 0 && child == state.heavy[vertex] {
                child = state.next_sibling[child]
            }
            if child >= 0 {
                state.frame_child[frame] = state.next_sibling[child]
                state.frame_vertex[frame_count] = child
                state.frame_keep[frame_count] = false
                state.frame_stage[frame_count] = 0
                state.frame_child[frame_count] = state.first_child[child]
                frame_count++
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
                frame_count++
            }
        } else {
            mut child := state.first_child[vertex]
            for child >= 0 {
                if child != state.heavy[vertex] {
                    add_interval(mut state, colors, state.tin[child], state.subtree_size[child], 1)
                }
                child = state.next_sibling[child]
            }
            color := colors[vertex]
            if state.frequency[color] == 0 { state.distinct++ }
            state.frequency[color]++
            state.answer[vertex] = state.distinct
            if !state.frame_keep[frame] {
                add_interval(mut state, colors, state.tin[vertex], state.subtree_size[vertex], -1)
            }
            frame_count--
        }
    }
}

@[export: 'tree_subtree_distinct_sack']
pub fn tree_subtree_distinct_sack(input &i64, length usize, mut output &u8, capacity usize) i64 {
    unsafe {
        if input == nil || length < 2 || length > 130 { return -1 }
        n_value := input[0]
        if n_value < 1 || n_value > 64 || length != usize(2 * n_value) { return -1 }
        n := int(n_value)
        for vertex in 1 .. n {
            if input[vertex] < 0 || input[vertex] >= i64(vertex) { return -1 }
        }
        mut colors := [64]int{}
        for vertex in 0 .. n {
            color := input[n + vertex]
            if color < 0 || color > 255 { return -1 }
            colors[vertex] = int(color)
        }
        required := 8 * n
        if output == nil || capacity < usize(required) { return -2 }

        mut state := SackState{}
        state.n = n
        for vertex in 0 .. n { state.first_child[vertex] = -1 }
        for vertex in 1 .. n {
            parent := int(input[vertex])
            state.parent[vertex] = parent
            state.next_sibling[vertex] = state.first_child[parent]
            state.first_child[parent] = vertex
        }
        solve_sack(mut state, colors)
        for vertex in 0 .. n {
            bits := u64(state.answer[vertex])
            for byte in 0 .. 8 { output[8*vertex+byte] = u8(bits >> (8*byte)) }
        }
        return i64(required)
    }
}
