const MAX_VERTICES: usize = 256;
const MAX_WORDS: usize = 4;
const MAX_CELLS: usize = MAX_VERTICES * MAX_WORDS;
const MAX_PARSEABLE_INPUT_LENGTH: usize = 1026;

#[inline]
fn write_u16_le(output: *mut u8, position: usize, value: u16) {
    unsafe {
        *output.add(position) = value as u8;
        *output.add(position + 1) = (value >> 8) as u8;
    }
}

#[no_mangle]
pub unsafe extern "C" fn kosaraju_dense_bitset_scc(input: *const i64, length: usize,
                                                   output: *mut u8, output_capacity: usize) -> i64 {
    if input.is_null() || length < 1 || length > MAX_PARSEABLE_INPUT_LENGTH { return -1; }
    let n_value = *input;
    if !(1..=MAX_VERTICES as i64).contains(&n_value) { return -1; }
    let n = n_value as usize;
    let words = (n + 63) / 64;
    if length != 1 + n * words { return -1; }

    let mut adjacency = [0u64; MAX_CELLS];
    let mut transpose = [0u64; MAX_CELLS];
    for cell in 0..n * words { adjacency[cell] = *input.add(1 + cell) as u64; }
    if (n & 63) != 0 {
        let valid = (1u64 << (n & 63)) - 1;
        for vertex in 0..n {
            if adjacency[vertex * words + words - 1] & !valid != 0 { return -1; }
        }
    }
    for source in 0..n {
        for word in 0..words {
            let mut bits = adjacency[source * words + word];
            while bits != 0 {
                let bit = bits.trailing_zeros() as usize;
                let target = word * 64 + bit;
                transpose[target * words + source / 64] |= 1u64 << (source & 63);
                bits &= bits - 1;
            }
        }
    }

    let mut unvisited = [u64::MAX; MAX_WORDS];
    if (n & 63) != 0 { unvisited[words - 1] = (1u64 << (n & 63)) - 1; }
    let mut stack = [0u16; MAX_VERTICES];
    let mut next_word = [0u16; MAX_VERTICES];
    let mut order = [0u16; MAX_VERTICES];
    let mut order_length = 0usize;
    for root in 0..n {
        let root_word = root / 64;
        let root_bit = root & 63;
        if ((unvisited[root_word] >> root_bit) & 1) == 0 { continue; }
        unvisited[root_word] &= !(1u64 << root_bit);
        let mut stack_length = 1usize;
        stack[0] = root as u16;
        next_word[0] = 0;
        while stack_length != 0 {
            let depth = stack_length - 1;
            let vertex = stack[depth] as usize;
            let mut pushed = false;
            while (next_word[depth] as usize) < words {
                let word = next_word[depth] as usize;
                let candidates = adjacency[vertex * words + word] & unvisited[word];
                if candidates != 0 {
                    let bit = candidates.trailing_zeros() as usize;
                    let neighbor = word * 64 + bit;
                    unvisited[word] &= !(1u64 << bit);
                    stack[stack_length] = neighbor as u16;
                    next_word[stack_length] = 0;
                    stack_length += 1;
                    pushed = true;
                    break;
                }
                next_word[depth] += 1;
            }
            if !pushed && next_word[depth] as usize == words {
                order[order_length] = vertex as u16;
                order_length += 1;
                stack_length -= 1;
            }
        }
    }

    unvisited[..words].fill(u64::MAX);
    if (n & 63) != 0 { unvisited[words - 1] = (1u64 << (n & 63)) - 1; }
    let mut raw_component = [0u16; MAX_VERTICES];
    let mut component_count = 0u16;
    while order_length != 0 {
        order_length -= 1;
        let root = order[order_length] as usize;
        let root_word = root / 64;
        let root_bit = root & 63;
        if ((unvisited[root_word] >> root_bit) & 1) == 0 { continue; }
        unvisited[root_word] &= !(1u64 << root_bit);
        let mut stack_length = 1usize;
        stack[0] = root as u16;
        raw_component[root] = component_count;
        while stack_length != 0 {
            stack_length -= 1;
            let vertex = stack[stack_length] as usize;
            for word in 0..words {
                let mut candidates = transpose[vertex * words + word] & unvisited[word];
                while candidates != 0 {
                    let bit = candidates.trailing_zeros() as usize;
                    let neighbor = word * 64 + bit;
                    let selected = 1u64 << bit;
                    unvisited[word] &= !selected;
                    candidates &= !selected;
                    raw_component[neighbor] = component_count;
                    stack[stack_length] = neighbor as u16;
                    stack_length += 1;
                }
            }
        }
        component_count += 1;
    }

    let mut remap = [u16::MAX; MAX_VERTICES];
    let mut canonical_count = 0u16;
    for vertex in 0..n {
        let raw = raw_component[vertex] as usize;
        if remap[raw] == u16::MAX {
            remap[raw] = canonical_count;
            canonical_count += 1;
        }
    }
    let output_length = 2 + 2 * n;
    if output.is_null() || output_capacity < output_length { return -2; }
    write_u16_le(output, 0, canonical_count);
    for vertex in 0..n { write_u16_le(output, 2 + 2 * vertex, remap[raw_component[vertex] as usize]); }
    output_length as i64
}
