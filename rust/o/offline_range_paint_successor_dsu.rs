const MAX_N: i64 = 64;
const MAX_Q: i64 = 64;
const MAX_INPUT_LENGTH: usize = 195;

fn find_successor(parent: &mut [i64; 65], node: usize) -> usize {
    let mut root = node;
    while parent[root] as usize != root { root = parent[root] as usize; }
    let mut current = node;
    while parent[current] as usize != current {
        let next = parent[current] as usize;
        parent[current] = root as i64;
        current = next;
    }
    root
}

#[no_mangle]
pub unsafe extern "C" fn offline_range_paint_successor_dsu(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT_LENGTH { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let (n_value, q_value) = (values[0], values[1]);
    if n_value < 1 || n_value > MAX_N || q_value < 0 || q_value > MAX_Q { return -1; }
    let (n, q) = (n_value as usize, q_value as usize);
    if length != 2 + 3 * q { return -1; }
    let mut left = [0i64; 64];
    let mut right = [0i64; 64];
    let mut color = [0i64; 64];
    for j in 0..q {
        left[j] = values[2 + 3 * j]; right[j] = values[3 + 3 * j]; color[j] = values[4 + 3 * j];
        if left[j] < 0 || left[j] > right[j] || right[j] >= n_value || !(-1000..=1000).contains(&color[j]) { return -1; }
    }
    let mut parent = [0i64; 65];
    let mut final_color = [0i64; 64];
    for i in 0..=n { parent[i] = i as i64; }
    for reverse_index in 0..q {
        let operation = q - reverse_index - 1;
        let mut cell = find_successor(&mut parent, left[operation] as usize);
        while cell <= right[operation] as usize {
            final_color[cell] = color[operation];
            parent[cell] = find_successor(&mut parent, cell + 1) as i64;
            cell = find_successor(&mut parent, cell);
        }
    }
    let mut checksum = 0i64;
    for i in 0..n { checksum += (i as i64 + 1) * (final_color[i] + 1001); }
    checksum
}
