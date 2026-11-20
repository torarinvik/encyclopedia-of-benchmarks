use std::slice;

const MAX_N: usize = 64;
const MAX_Q: usize = 32;
const LOG_LEVELS: usize = 6;

#[derive(Default)]
struct LongChainAncestorState {
    parent: [i64; MAX_N],
    depth: [i64; MAX_N],
    height: [i64; MAX_N],
    heavy: [i64; MAX_N],
    chain_head: [i64; MAX_N],
    chain_position: [i64; MAX_N],
    chain_base: [i64; MAX_N],
    chain_nodes: [i64; MAX_N],
    head_ancestors: [i64; MAX_N],
    up: [[i64; MAX_N]; LOG_LEVELS],
}

unsafe fn write_i64(output: *mut u8, offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 {
        *output.add(offset + byte) = (bits >> (8 * byte)) as u8;
    }
}

#[no_mangle]
pub unsafe extern "C" fn long_chain_kth_ancestor(
    input: *const i64, length: usize, output: *mut u8, output_capacity: usize,
) -> i64 {
    if input.is_null() || length < 2 || length > 130 { return -1; }
    let values = slice::from_raw_parts(input, length);
    let n_value = values[0];
    let q_value = values[1];
    if !(1..=MAX_N as i64).contains(&n_value) || !(1..=MAX_Q as i64).contains(&q_value) { return -1; }
    let n = n_value as usize;
    let q = q_value as usize;
    if length != n + 1 + 2 * q { return -1; }
    for vertex in 1..n {
        if values[1 + vertex] < 0 || values[1 + vertex] >= vertex as i64 { return -1; }
    }
    let query_start = n + 1;
    for query in 0..q {
        let vertex = values[query_start + 2 * query];
        let distance = values[query_start + 2 * query + 1];
        if vertex < 0 || vertex >= n_value || !(0..MAX_N as i64).contains(&distance) { return -1; }
    }
    let required = 8 * q;
    if output.is_null() || output_capacity < required { return -2; }

    let mut state = LongChainAncestorState::default();
    state.parent[0] = -1;
    for vertex in 0..n {
        state.heavy[vertex] = -1;
        state.chain_head[vertex] = -1;
        state.chain_base[vertex] = -1;
        state.height[vertex] = 1;
        if vertex > 0 {
            state.parent[vertex] = values[1 + vertex];
            state.depth[vertex] = state.depth[state.parent[vertex] as usize] + 1;
        }
    }
    for reverse in 1..n {
        let vertex = n - 1 - (reverse - 1);
        let parent = state.parent[vertex] as usize;
        let old = state.heavy[parent];
        if old < 0 || state.height[vertex] > state.height[old as usize]
            || (state.height[vertex] == state.height[old as usize] && (vertex as i64) < old) {
            state.heavy[parent] = vertex as i64;
        }
        state.height[parent] = state.height[parent].max(state.height[vertex] + 1);
    }

    let mut pool = 0_usize;
    for vertex in 0..n {
        if vertex == 0 || state.heavy[state.parent[vertex] as usize] != vertex as i64 {
            state.chain_base[vertex] = pool as i64;
            let mut current = vertex as i64;
            let mut position = 0_usize;
            while current >= 0 {
                let index = current as usize;
                state.chain_head[index] = vertex as i64;
                state.chain_position[index] = position as i64;
                state.chain_nodes[pool + position] = current;
                current = state.heavy[index];
                position += 1;
            }
            current = state.parent[vertex];
            for step in 0..position {
                state.head_ancestors[pool + step] = current;
                current = if current >= 0 { state.parent[current as usize] } else { -1 };
            }
            pool += position;
        }
    }
    for vertex in 0..n { state.up[0][vertex] = state.parent[vertex]; }
    for level in 1..LOG_LEVELS {
        for vertex in 0..n {
            let halfway = state.up[level - 1][vertex];
            state.up[level][vertex] = if halfway >= 0 {
                state.up[level - 1][halfway as usize]
            } else { -1 };
        }
    }

    for query in 0..q {
        let vertex = values[query_start + 2 * query] as usize;
        let distance = values[query_start + 2 * query + 1] as usize;
        let mut answer = -1_i64;
        if distance <= state.depth[vertex] as usize {
            if distance == 0 {
                answer = vertex as i64;
            } else {
                let mut level = 0_usize;
                let mut value = distance;
                while value > 1 { level += 1; value >>= 1; }
                let jumped = state.up[level][vertex] as usize;
                let remaining = distance - (1_usize << level);
                let head = state.chain_head[jumped] as usize;
                let position = state.chain_position[jumped] as usize;
                let base = state.chain_base[head] as usize;
                if remaining <= position {
                    answer = state.chain_nodes[base + position - remaining];
                } else {
                    let steps = remaining - position;
                    if steps <= state.height[head] as usize {
                        answer = state.head_ancestors[base + steps - 1];
                    }
                }
            }
        }
        write_i64(output, 8 * query, answer);
    }
    required as i64
}
