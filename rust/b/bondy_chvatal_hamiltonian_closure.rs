const MAX_VERTICES: usize = 8;
const MAX_EDGES: usize = 28;
const MAX_INPUT_WORDS: usize = 59;
const MAX_OUTPUT_WORDS: usize = 10;

fn store_i64_le(output: &mut [u8], offset: usize, value: i64) {
    for byte in 0..8 {
        output[offset + byte] = ((value as u64) >> (8 * byte)) as u8;
    }
}

#[no_mangle]
pub unsafe extern "C" fn bondy_chvatal_hamiltonian_closure(
    raw: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if raw.is_null() || length < 2 || length > MAX_INPUT_WORDS { return -1; }
    let input = unsafe { std::slice::from_raw_parts(raw, length) };
    let n_word = input[0];
    let m_word = input[1];
    if !(3..=MAX_VERTICES as i64).contains(&n_word) || m_word < 0 || m_word > MAX_EDGES as i64 { return -1; }
    let n = n_word as usize;
    let m = m_word as usize;
    if m > n * (n - 1) / 2 || length != 2 + 2 * m { return -1; }

    let mut adjacency = [[false; MAX_VERTICES]; MAX_VERTICES];
    for edge in 0..m {
        let u_word = input[2 + 2 * edge];
        let v_word = input[3 + 2 * edge];
        if u_word < 0 || u_word >= n_word || v_word < 0 || v_word >= n_word || u_word == v_word { return -1; }
        let u = u_word as usize;
        let v = v_word as usize;
        if adjacency[u][v] { return -1; }
        adjacency[u][v] = true;
        adjacency[v][u] = true;
    }

    let mut added = 0_i64;
    loop {
        let mut degree = [0_usize; MAX_VERTICES];
        for u in 0..n {
            for v in 0..n {
                if adjacency[u][v] { degree[u] += 1; }
            }
        }
        let mut chosen = None;
        'pairs: for u in 0..n {
            for v in (u + 1)..n {
                if !adjacency[u][v] && degree[u] + degree[v] >= n {
                    chosen = Some((u, v));
                    break 'pairs;
                }
            }
        }
        let Some((u, v)) = chosen else { break; };
        adjacency[u][v] = true;
        adjacency[v][u] = true;
        added += 1;
    }

    let mut staged = [0_i64; MAX_OUTPUT_WORDS];
    let full_mask = (1_usize << n) - 1;
    let mut complete = true;
    for u in 0..n {
        let mut row = 0_usize;
        for v in 0..n {
            if adjacency[u][v] { row |= 1_usize << v; }
        }
        staged[2 + u] = row as i64;
        if row != (full_mask ^ (1_usize << u)) { complete = false; }
    }
    staged[0] = if complete { 1 } else { 0 };
    staged[1] = added;

    let output_bytes = (2 + n) * 8;
    if output.is_null() || capacity < output_bytes { return -2; }
    let destination = unsafe { std::slice::from_raw_parts_mut(output, output_bytes) };
    for word in 0..(2 + n) { store_i64_le(destination, word * 8, staged[word]); }
    output_bytes as i64
}
