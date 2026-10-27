const MAX_N: usize = 8;
const MAX_INPUT: usize = MAX_N + 1;
const MAX_CLIQUES: usize = 256;
const MAX_OUTPUT_BYTES: usize = 8 + MAX_CLIQUES;

struct SearchState {
    n: usize,
    adjacency: [u16; MAX_N],
    masks: [u8; MAX_CLIQUES],
    count: usize,
}

fn visit(state: &mut SearchState, clique: u16) {
    state.masks[state.count] = clique as u8;
    state.count += 1;
    let mut minimum = state.n;
    for vertex in 0..state.n {
        if clique & (1u16 << vertex) != 0 { minimum = vertex; break; }
    }
    for vertex in 0..minimum {
        let bit = 1u16 << vertex;
        if clique & bit == 0 && state.adjacency[vertex] & clique == clique {
            visit(state, clique | bit);
        }
    }
}

unsafe fn store_i64_le(output: *mut u8, value: i64) {
    let bits = value as u64;
    for byte in 0..8 { *output.add(byte) = (bits >> (8 * byte)) as u8; }
}

#[no_mangle]
pub unsafe extern "C" fn clique_reverse_search_enumeration(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT { return -1; }
    let n_value = *input;
    if n_value < 1 || n_value > MAX_N as i64 || length != n_value as usize + 1 { return -1; }
    let n = n_value as usize;
    let mut state = SearchState { n, adjacency: [0; MAX_N], masks: [0; MAX_CLIQUES], count: 0 };
    for vertex in 0..n {
        let raw = *input.add(vertex + 1);
        if raw < 0 || raw >= (1i64 << n) || raw & (1i64 << vertex) != 0 { return -1; }
        state.adjacency[vertex] = raw as u16;
    }
    for left in 0..n {
        for right in left + 1..n {
            let edge_left = state.adjacency[left] & (1u16 << right) != 0;
            let edge_right = state.adjacency[right] & (1u16 << left) != 0;
            if edge_left != edge_right { return -1; }
        }
    }
    visit(&mut state, 0);
    let required = 8 + state.count;
    if output.is_null() || capacity < required { return -2; }
    let mut staged = [0u8; MAX_OUTPUT_BYTES];
    store_i64_le(staged.as_mut_ptr(), state.count as i64);
    for index in 0..state.count { staged[8 + index] = state.masks[index]; }
    for byte in 0..required { *output.add(byte) = staged[byte]; }
    required as i64
}
