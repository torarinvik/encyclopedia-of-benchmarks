/// Flatten an indexed tree in place to its preorder right-child chain.
const MAX_NODES: usize = 1023;
const MAX_HEIGHT: usize = 512;

fn validate(nodes: &[i64], count: usize, index: i64, depth: usize,
            visited: &mut [bool; MAX_NODES], seen: &mut usize) -> bool {
    if index == -1 { return true; }
    if index < 0 || index as usize >= count || depth > MAX_HEIGHT { return false; }
    let node = index as usize;
    if visited[node] { return false; }
    visited[node] = true; *seen += 1;
    let off = 3 * node;
    let value = nodes[off]; let left = nodes[off + 1]; let right = nodes[off + 2];
    if value < i32::MIN as i64 || value > i32::MAX as i64 || left < -1 || right < -1 ||
        left >= count as i64 || right >= count as i64 { return false; }
    validate(nodes, count, left, depth + 1, visited, seen) &&
        validate(nodes, count, right, depth + 1, visited, seen)
}

fn flatten(nodes: &mut [i64], index: i64) {
    if index == -1 { return; }
    let off = 3 * index as usize;
    let left = nodes[off + 1];
    flatten(nodes, left);
    let original_right = nodes[off + 2];
    nodes[off + 2] = left; nodes[off + 1] = -1;
    let mut tail = index;
    while nodes[3 * tail as usize + 2] != -1 { tail = nodes[3 * tail as usize + 2]; }
    nodes[3 * tail as usize + 2] = original_right;
    flatten(nodes, original_right);
}

fn store(out: &mut [u8], off: usize, value: i64) {
    let bits = value as u64;
    for b in 0..8 { out[off + b] = (bits >> (8 * b)) as u8; }
}

#[no_mangle]
pub extern "C" fn flatten_binarytree_to_linkedlist(values: *const i64, length: usize,
    output: *mut u8, capacity: usize) -> i64 {
    if values.is_null() || length < 1 || (length - 1) % 3 != 0 || length > 1 + 3 * MAX_NODES { return -1; }
    let input = unsafe { std::slice::from_raw_parts(values, length) };
    let count = (length - 1) / 3; let root = input[0];
    if count == 0 { return if root == -1 { 0 } else { -1 }; }
    if root < 0 || root as usize >= count { return -1; }
    let mut nodes = [0i64; 3 * MAX_NODES];
    nodes[..3 * count].copy_from_slice(&input[1..]);
    let mut visited = [false; MAX_NODES]; let mut seen = 0;
    if !validate(&nodes, count, root, 1, &mut visited, &mut seen) || seen != count { return -1; }
    if output.is_null() || capacity < 24 * count { return -2; }
    flatten(&mut nodes, root);
    let out = unsafe { std::slice::from_raw_parts_mut(output, 24 * count) };
    for i in 0..count {
        store(out, 24 * i, nodes[3 * i]); store(out, 24 * i + 8, nodes[3 * i + 1]);
        store(out, 24 * i + 16, nodes[3 * i + 2]);
    }
    count as i64
}
