const MAX_N: usize = 4;
const MAX_INPUT: usize = 2;
const MAX_WORDS: usize = 97;

struct SearchState {
    n: usize,
    permutation: [i64; MAX_N],
    staged: [i64; MAX_WORDS],
    cursor: usize,
}

fn visit(state: &mut SearchState) {
    for index in 0..state.n {
        let cursor = state.cursor;
        state.staged[cursor] = state.permutation[index];
        state.cursor += 1;
    }

    let mut reverse_point = state.n;
    for index in 0..state.n.saturating_sub(1) {
        if state.permutation[index] > state.permutation[index + 1] {
            reverse_point = index + 1;
            break;
        }
    }

    for child in 1..reverse_point {
        state.permutation.swap(child - 1, child);
        visit(state);
        state.permutation.swap(child - 1, child);
    }

    if reverse_point + 2 <= state.n
        && state.permutation[reverse_point - 1] < state.permutation[reverse_point + 1]
    {
        state.permutation.swap(reverse_point, reverse_point + 1);
        visit(state);
        state.permutation.swap(reverse_point, reverse_point + 1);
    }
}

unsafe fn store_i64_le(output: *mut u8, offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 {
        *output.add(offset + byte) = (bits >> (8 * byte)) as u8;
    }
}

#[no_mangle]
pub unsafe extern "C" fn reverse_search_permutation_enumeration(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input.is_null() || length < 1 || length > MAX_INPUT { return -1; }
    let n_value = *input;
    if length != 1 || n_value < 1 || n_value > MAX_N as i64 { return -1; }
    let n = n_value as usize;
    let mut count = 1usize;
    for factor in 2..=n { count *= factor; }
    let words = 1 + n * count;
    let required = words * 8;
    if output.is_null() || capacity < required { return -2; }

    let mut state = SearchState {
        n,
        permutation: [0; MAX_N],
        staged: [0; MAX_WORDS],
        cursor: 1,
    };
    state.staged[0] = count as i64;
    for index in 0..n { state.permutation[index] = index as i64 + 1; }
    visit(&mut state);
    for word in 0..words { store_i64_le(output, word * 8, state.staged[word]); }
    required as i64
}
