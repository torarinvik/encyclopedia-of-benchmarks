const MAX_N: usize = 32;
const MAX_M: usize = 128;
const MAX_INPUT: usize = 258;

fn put_i64_le(output: &mut [u8], word: usize, value: u64) {
    let bytes = value.to_le_bytes();
    output[word * 8..word * 8 + 8].copy_from_slice(&bytes);
}

#[no_mangle]
pub unsafe extern "C" fn sugiyama_longest_path_layer_assignment(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT + 1 { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    if values[0] < 0 || values[0] > MAX_N as i64 || values[1] < 0 || values[1] > MAX_M as i64 {
        return -1;
    }
    let n = values[0] as usize;
    let m = values[1] as usize;
    if length != 2 + 2 * m { return -1; }

    let mut adjacency = [0u32; MAX_N];
    for edge in 0..m {
        let source = values[2 + 2 * edge];
        let target = values[3 + 2 * edge];
        if source < 0 || source >= n as i64 || target < 0 || target >= n as i64 { return -1; }
        let bit = 1u32 << target as u32;
        if adjacency[source as usize] & bit != 0 { return -1; }
        adjacency[source as usize] |= bit;
    }

    let mut removed = [false; MAX_N];
    let mut sink_depth = [0usize; MAX_N];
    let mut remaining = n;
    let mut depth = 0usize;
    while remaining > 0 {
        let mut sinks = [false; MAX_N];
        let mut sink_count = 0usize;
        for vertex in 0..n {
            if removed[vertex] { continue; }
            let mut has_remaining_successor = false;
            for target in 0..n {
                if !removed[target] && adjacency[vertex] & (1u32 << target) != 0 {
                    has_remaining_successor = true;
                    break;
                }
            }
            if !has_remaining_successor { sinks[vertex] = true; sink_count += 1; }
        }
        if sink_count == 0 { return -1; }
        for vertex in 0..n {
            if sinks[vertex] { removed[vertex] = true; sink_depth[vertex] = depth; }
        }
        remaining -= sink_count;
        depth += 1;
    }

    let output_bytes = 8 * (n + 1);
    if output.is_null() || capacity < output_bytes { return -2; }
    let staged = std::slice::from_raw_parts_mut(output, output_bytes);
    put_i64_le(staged, 0, depth as u64);
    for vertex in 0..n {
        put_i64_le(staged, vertex + 1, (depth - 1 - sink_depth[vertex]) as u64);
    }
    output_bytes as i64
}
