/* DSU-on-tree distinct-color counts for all rooted subtrees. */
const MAX_N: usize = 64;
const MAX_COLORS: usize = 256;

#[derive(Default)]
struct SackState {
    n: usize,
    parent: [usize; MAX_N],
    first_child: [i32; MAX_N],
    next_sibling: [i32; MAX_N],
    order: [usize; MAX_N],
    tin: [usize; MAX_N],
    subtree_size: [usize; MAX_N],
    heavy: [i32; MAX_N],
    frequency: [usize; MAX_COLORS],
    answer: [usize; MAX_N],
    distinct: usize,
    frame_vertex: [usize; MAX_N],
    frame_keep: [bool; MAX_N],
    frame_stage: [u8; MAX_N],
    frame_child: [i32; MAX_N],
}

fn add_interval(state: &mut SackState, colors: &[usize; MAX_N], begin: usize,
                count: usize, delta: i32) {
    for position in begin..begin + count {
        let color = colors[state.order[position]];
        if delta > 0 {
            if state.frequency[color] == 0 { state.distinct += 1; }
            state.frequency[color] += 1;
        } else {
            state.frequency[color] -= 1;
            if state.frequency[color] == 0 { state.distinct -= 1; }
        }
    }
}

fn solve_sack(state: &mut SackState, colors: &[usize; MAX_N]) {
    let mut stack_next = [0_i32; MAX_N];
    let mut depth = 1_usize;
    let mut timer = 1_usize;
    state.order[0] = 0;
    state.tin[0] = 0;
    stack_next[0] = state.first_child[0];
    while depth > 0 {
        let frame = depth - 1;
        let child = stack_next[frame];
        if child >= 0 {
            let child_index = child as usize;
            stack_next[frame] = state.next_sibling[child_index];
            state.tin[child_index] = timer;
            state.order[timer] = child_index;
            timer += 1;
            stack_next[depth] = state.first_child[child_index];
            depth += 1;
        } else {
            depth -= 1;
        }
    }

    for vertex in 0..state.n {
        state.subtree_size[vertex] = 1;
        state.heavy[vertex] = -1;
    }
    for reverse in 0..state.n.saturating_sub(1) {
        let position = state.n - 1 - reverse;
        let vertex = state.order[position];
        let parent = state.parent[vertex];
        state.subtree_size[parent] += state.subtree_size[vertex];
        let old_heavy = state.heavy[parent];
        if old_heavy < 0 || state.subtree_size[vertex] > state.subtree_size[old_heavy as usize] {
            state.heavy[parent] = vertex as i32;
        }
    }

    let mut frame_count = 1_usize;
    state.frame_vertex[0] = 0;
    state.frame_keep[0] = false;
    state.frame_stage[0] = 0;
    state.frame_child[0] = state.first_child[0];
    while frame_count > 0 {
        let frame = frame_count - 1;
        let vertex = state.frame_vertex[frame];
        if state.frame_stage[frame] == 0 {
            let mut child = state.frame_child[frame];
            while child >= 0 && child == state.heavy[vertex] {
                child = state.next_sibling[child as usize];
            }
            if child >= 0 {
                let child_index = child as usize;
                state.frame_child[frame] = state.next_sibling[child_index];
                state.frame_vertex[frame_count] = child_index;
                state.frame_keep[frame_count] = false;
                state.frame_stage[frame_count] = 0;
                state.frame_child[frame_count] = state.first_child[child_index];
                frame_count += 1;
            } else {
                state.frame_stage[frame] = 1;
            }
        } else if state.frame_stage[frame] == 1 {
            state.frame_stage[frame] = 2;
            let child = state.heavy[vertex];
            if child >= 0 {
                let child_index = child as usize;
                state.frame_vertex[frame_count] = child_index;
                state.frame_keep[frame_count] = true;
                state.frame_stage[frame_count] = 0;
                state.frame_child[frame_count] = state.first_child[child_index];
                frame_count += 1;
            }
        } else {
            let mut child = state.first_child[vertex];
            while child >= 0 {
                let child_index = child as usize;
                if child != state.heavy[vertex] {
                    add_interval(state, colors, state.tin[child_index],
                                 state.subtree_size[child_index], 1);
                }
                child = state.next_sibling[child_index];
            }
            let color = colors[vertex];
            if state.frequency[color] == 0 { state.distinct += 1; }
            state.frequency[color] += 1;
            state.answer[vertex] = state.distinct;
            if !state.frame_keep[frame] {
                add_interval(state, colors, state.tin[vertex], state.subtree_size[vertex], -1);
            }
            frame_count -= 1;
        }
    }
}

unsafe fn write_i64(output: *mut u8, offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 {
        *output.add(offset + byte) = (bits >> (byte * 8)) as u8;
    }
}

#[no_mangle]
pub unsafe extern "C" fn tree_subtree_distinct_sack(
    input: *const i64, length: usize, output: *mut u8, output_capacity: usize,
) -> i64 {
    if input.is_null() || length < 2 || length > 130 { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let n_value = values[0];
    if !(1..=MAX_N as i64).contains(&n_value) || length != 2 * n_value as usize { return -1; }
    let n = n_value as usize;
    for vertex in 1..n {
        if values[vertex] < 0 || values[vertex] >= vertex as i64 { return -1; }
    }
    let mut colors = [0_usize; MAX_N];
    for vertex in 0..n {
        let color = values[n + vertex];
        if !(0..MAX_COLORS as i64).contains(&color) { return -1; }
        colors[vertex] = color as usize;
    }
    let required = 8 * n;
    if output.is_null() || output_capacity < required { return -2; }

    let mut state = SackState { n, ..SackState::default() };
    state.first_child.fill(-1);
    for vertex in 1..n {
        let parent = values[vertex] as usize;
        state.parent[vertex] = parent;
        state.next_sibling[vertex] = state.first_child[parent];
        state.first_child[parent] = vertex as i32;
    }
    solve_sack(&mut state, &colors);
    for vertex in 0..n {
        write_i64(output, 8 * vertex, state.answer[vertex] as i64);
    }
    required as i64
}
