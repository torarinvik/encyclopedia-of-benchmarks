const MAX_LEAVES: usize = 8;
const MAX_EDGES: usize = 13;
const MAX_INPUT: usize = 27;

unsafe fn store_i64_le(output: *mut u8, value: i64) {
    let bits = value as u64;
    for byte in 0..8 { *output.add(byte) = (bits >> (8 * byte)) as u8; }
}

fn bit_count(value: u64, n: usize) -> usize {
    let mut count = 0;
    for bit in 0..n { count += ((value >> bit) & 1) as usize; }
    count
}

fn valid_tree(input: &[i64], offset: usize, n: usize, edges: usize) -> bool {
    let mut masks = [0u64; MAX_EDGES];
    let mut internal = [0u64; MAX_EDGES];
    let mut internal_count = 0;
    let universe = (1u64 << n) - 1;
    for edge in 0..edges {
        let raw = input[offset + edge];
        if raw <= 0 || raw as u64 >= universe || raw & 1 != 0 { return false; }
        masks[edge] = raw as u64;
        for earlier in 0..edge { if masks[earlier] == masks[edge] { return false; } }
        let size = bit_count(masks[edge], n);
        if size == 1 || size == n - 1 {
            if size == n - 1 && masks[edge] != universe ^ 1 { return false; }
        } else if size >= 2 && size <= n - 2 {
            internal[internal_count] = masks[edge];
            internal_count += 1;
        } else { return false; }
    }
    if internal_count != n - 3 { return false; }
    for leaf in 1..n {
        let pendant = 1u64 << leaf;
        let mut found = 0;
        for edge in 0..edges { if masks[edge] == pendant { found += 1; } }
        if found != 1 { return false; }
    }
    let mut root_pendant = 0;
    for edge in 0..edges { if masks[edge] == universe ^ 1 { root_pendant += 1; } }
    if root_pendant != 1 { return false; }
    for i in 0..internal_count {
        for j in i + 1..internal_count {
            let intersection = internal[i] & internal[j];
            if intersection != 0 && intersection != internal[i] && intersection != internal[j] { return false; }
        }
    }
    true
}

#[no_mangle]
pub unsafe extern "C" fn non_shared_edges(input: *const i64, length: usize,
                                            output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 7 || length > MAX_INPUT { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let leaf_value = values[0];
    if leaf_value < 3 || leaf_value > MAX_LEAVES as i64 { return -1; }
    let leaves = leaf_value as usize;
    let edges = 2 * leaves - 3;
    if length != 1 + 2 * edges { return -1; }
    let second = 1 + edges;
    if !valid_tree(values, 1, leaves, edges) || !valid_tree(values, second, leaves, edges) { return -1; }
    let mut shared = 0i64;
    for left in 0..edges {
        for right in 0..edges {
            if values[1 + left] == values[second + right] { shared += 1; break; }
        }
    }
    if output.is_null() || capacity < 8 { return -2; }
    let mut staged = [0u8; 8];
    store_i64_le(staged.as_mut_ptr(), edges as i64 - shared);
    for byte in 0..8 { *output.add(byte) = staged[byte]; }
    8
}
