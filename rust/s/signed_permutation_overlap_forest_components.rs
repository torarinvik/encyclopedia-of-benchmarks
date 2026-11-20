const MAX_N: usize = 8;
const MAX_VERTICES: usize = 2 * MAX_N + 2;
const MAX_CYCLES: usize = MAX_N + 1;
const MAX_INPUT: usize = MAX_N + 2;
const MAX_OUTPUT: usize = 8 * (1 + 3 * MAX_CYCLES);

fn store_word(bytes: &mut [u8; MAX_OUTPUT], word: usize, value: i64) {
    bytes[word * 8..word * 8 + 8].copy_from_slice(&value.to_le_bytes());
}

#[no_mangle]
pub unsafe extern "C" fn signed_permutation_overlap_forest_components(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let n_value = values[0];
    if n_value < 1 || n_value > MAX_N as i64 || length != n_value as usize + 1 { return -1; }
    let n = n_value as usize;
    let vertex_count = 2 * n + 2;
    let mut pi = [0usize; MAX_VERTICES];
    pi[vertex_count - 1] = vertex_count - 1;
    let mut seen = 0u16;
    for position in 0..n {
        let gene = values[position + 1];
        if gene == 0 || gene < -(n as i64) || gene > n as i64 { return -1; }
        let absolute = if gene < 0 { (-gene) as usize } else { gene as usize };
        let bit = 1u16 << (absolute - 1);
        if seen & bit != 0 { return -1; }
        seen |= bit;
        let mut left = 2 * absolute - 1;
        let mut right = 2 * absolute;
        if gene < 0 { std::mem::swap(&mut left, &mut right); }
        pi[2 * position + 1] = left;
        pi[2 * position + 2] = right;
    }
    let mut gray = [0usize; MAX_VERTICES];
    for pair in 0..=n {
        let left = pi[2 * pair];
        let right = pi[2 * pair + 1];
        gray[left] = right;
        gray[right] = left;
    }
    let mut cycle_of = [-1i32; MAX_VERTICES];
    let mut begin = [0usize; MAX_CYCLES];
    let mut end = [0usize; MAX_CYCLES];
    let mut cycle_count = 0usize;
    for seed in 0..vertex_count {
        if cycle_of[seed] >= 0 { continue; }
        let cid = cycle_count;
        cycle_count += 1;
        let mut vertex = seed;
        let mut low = seed;
        let mut high = seed;
        while cycle_of[vertex] < 0 {
            cycle_of[vertex] = cid as i32;
            low = low.min(vertex);
            high = high.max(vertex);
            vertex = gray[vertex ^ 1];
        }
        begin[cid] = low;
        end[cid] = high;
    }

    let mut parent = [0usize; MAX_CYCLES];
    for cid in 0..cycle_count { parent[cid] = cid; }
    let mut stack_id = [0usize; MAX_CYCLES];
    let mut stack_begin = [0usize; MAX_CYCLES];
    let mut stack_end = [0usize; MAX_CYCLES];
    let mut top = 0usize;
    for vertex in 0..vertex_count {
        let cid = cycle_of[vertex] as usize;
        let low = begin[cid];
        let high = end[cid];
        if vertex == low {
            stack_id[top] = cid;
            stack_begin[top] = low;
            stack_end[top] = high;
            top += 1;
        }
        let mut extent_begin = low;
        let mut extent_end = high;
        while top != 0 && stack_begin[top - 1] > low {
            top -= 1;
            let popped = stack_id[top];
            extent_begin = extent_begin.min(stack_begin[top]);
            extent_end = extent_end.max(stack_end[top]);
            parent[popped] = cid;
        }
        if top == 0 { return -1; }
        stack_begin[top - 1] = stack_begin[top - 1].min(extent_begin);
        stack_end[top - 1] = stack_end[top - 1].max(extent_end);
        if vertex == stack_end[top - 1] { top -= 1; }
    }

    let mut component = [0usize; MAX_CYCLES];
    for cid in 0..cycle_count {
        component[cid] = if parent[cid] == cid { begin[cid] } else { component[parent[cid]] };
    }
    let mut words = [0i64; 1 + 3 * MAX_CYCLES];
    words[0] = cycle_count as i64;
    for cid in 0..cycle_count {
        words[1 + 3 * cid] = begin[cid] as i64;
        words[2 + 3 * cid] = end[cid] as i64;
        words[3 + 3 * cid] = component[cid] as i64;
    }
    let bytes_needed = (1 + 3 * cycle_count) * 8;
    if output.is_null() || capacity < bytes_needed { return -2; }
    let mut staged = [0u8; MAX_OUTPUT];
    for word in 0..1 + 3 * cycle_count { store_word(&mut staged, word, words[word]); }
    for byte in 0..bytes_needed { *output.add(byte) = staged[byte]; }
    bytes_needed as i64
}
