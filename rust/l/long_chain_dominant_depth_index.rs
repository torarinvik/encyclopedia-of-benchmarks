use std::slice;

const MAX_N: usize = 64;

#[derive(Default)]
struct LongChainState {
    parent: [i64; MAX_N],
    first_child: [i64; MAX_N],
    next_sibling: [i64; MAX_N],
    height: [i64; MAX_N],
    heavy: [i64; MAX_N],
    base: [i64; MAX_N],
    count: [i64; MAX_N],
    dominant_depth: [i64; MAX_N],
}

unsafe fn write_i64(output: *mut u8, offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 {
        *output.add(offset + byte) = (bits >> (byte * 8)) as u8;
    }
}

#[no_mangle]
pub unsafe extern "C" fn long_chain_dominant_depth_index(
    input: *const i64, length: usize, output: *mut u8, output_capacity: usize,
) -> i64 {
    if input.is_null() || length == 0 || length > MAX_N + 1 { return -1; }
    let values = slice::from_raw_parts(input, length);
    let n_value = values[0];
    if !(1..=MAX_N as i64).contains(&n_value) || length != n_value as usize { return -1; }
    let n = n_value as usize;
    for vertex in 1..n {
        if values[vertex] < 0 || values[vertex] >= vertex as i64 { return -1; }
    }
    let required = 8 * n;
    if output.is_null() || output_capacity < required { return -2; }

    let mut state = LongChainState::default();
    for vertex in 0..n {
        state.first_child[vertex] = -1;
        state.heavy[vertex] = -1;
        state.height[vertex] = 1;
    }
    state.parent[0] = -1;
    for vertex in 1..n {
        let parent = values[vertex] as usize;
        state.parent[vertex] = parent as i64;
        state.next_sibling[vertex] = state.first_child[parent];
        state.first_child[parent] = vertex as i64;
    }

    for reverse in 0..n {
        let vertex = n - 1 - reverse;
        let mut child = state.first_child[vertex];
        let mut maximum_height = 0;
        while child >= 0 {
            let child_index = child as usize;
            let child_height = state.height[child_index];
            if child_height > maximum_height ||
                (child_height == maximum_height && child < state.heavy[vertex]) {
                maximum_height = child_height;
                state.heavy[vertex] = child;
            }
            child = state.next_sibling[child_index];
        }
        state.height[vertex] = maximum_height + 1;
    }

    let mut pool_size = 0_i64;
    for vertex in 0..n {
        if vertex == 0 || state.heavy[state.parent[vertex] as usize] != vertex as i64 {
            let mut current = vertex as i64;
            while current >= 0 {
                state.base[current as usize] = pool_size;
                pool_size += 1;
                current = state.heavy[current as usize];
            }
        }
    }

    for reverse in 0..n {
        let vertex = n - 1 - reverse;
        let base = state.base[vertex] as usize;
        state.count[base] = 1;
        let mut best_depth = 0_i64;
        let mut best_count = 1_i64;
        let heavy = state.heavy[vertex];
        if heavy >= 0 {
            best_depth = state.dominant_depth[heavy as usize] + 1;
            best_count = state.count[base + best_depth as usize];
        }
        let mut child = state.first_child[vertex];
        while child >= 0 {
            let child_index = child as usize;
            if child != heavy {
                let child_base = state.base[child_index] as usize;
                for child_depth in 0..state.height[child_index] as usize {
                    let depth = child_depth + 1;
                    let slot = base + depth;
                    let count = state.count[slot] + state.count[child_base + child_depth];
                    state.count[slot] = count;
                    if count > best_count || (count == best_count && (depth as i64) < best_depth) {
                        best_count = count;
                        best_depth = depth as i64;
                    }
                }
            }
            child = state.next_sibling[child_index];
        }
        state.dominant_depth[vertex] = best_depth;
    }
    for vertex in 0..n {
        write_i64(output, 8 * vertex, state.dominant_depth[vertex]);
    }
    required as i64
}
