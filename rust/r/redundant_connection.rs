/// Return the edge that first closes the cycle under input-order union-find.
const MAX_VERTICES: usize = 1000;

fn find_root(parents: &mut [i32; MAX_VERTICES + 1], mut node: i32) -> i32 {
    let mut root = node;
    while parents[root as usize] != root { root = parents[root as usize]; }
    while parents[node as usize] != node {
        let next = parents[node as usize];
        parents[node as usize] = root;
        node = next;
    }
    root
}

#[no_mangle]
pub extern "C" fn redundant_connection(
    values: *const i64, length: usize, output: *mut u8, output_capacity: usize,
) -> i64 {
    if length < 6 || length > 2 * MAX_VERTICES || length % 2 != 0 || values.is_null() { return -1; }
    let edge_count = length / 2;
    let input = unsafe { std::slice::from_raw_parts(values, length) };
    if input.iter().any(|&value| value < 1 || value > edge_count as i64) { return -1; }
    for edge in 0..edge_count {
        if input[2 * edge] == input[2 * edge + 1] { return -1; }
    }

    let mut parents = [0i32; MAX_VERTICES + 1];
    for node in 0..=edge_count { parents[node] = node as i32; }
    let mut redundant = (0i64, 0i64);
    let mut redundant_count = 0usize;
    for edge in 0..edge_count {
        let left = input[2 * edge] as i32;
        let right = input[2 * edge + 1] as i32;
        let left_root = find_root(&mut parents, left);
        let right_root = find_root(&mut parents, right);
        if left_root == right_root {
            redundant = (i64::from(left), i64::from(right));
            redundant_count += 1;
        } else {
            parents[left_root as usize] = right_root;
        }
    }
    if redundant_count != 1 { return -1; }
    if output_capacity < 8 || output.is_null() { return -2; }
    for (endpoint, value) in [redundant.0, redundant.1].into_iter().enumerate() {
        let bytes = (value as i32).to_le_bytes();
        for (byte, value) in bytes.iter().enumerate() {
            unsafe { *output.add(endpoint * 4 + byte) = *value; }
        }
    }
    2
}
