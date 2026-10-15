/// Recursively swap each node's children in a copied indexed binary tree.
const MAX_NODE_COUNT: usize = 1023;
const MAX_TREE_HEIGHT: usize = 512;

fn validate_subtree(values: &[i64], node_count: usize, index: i64, depth: usize,
                    visited: &mut [bool; MAX_NODE_COUNT]) -> bool {
    if index == -1 { return true; }
    if index < 0 || index as usize >= node_count || depth > MAX_TREE_HEIGHT { return false; }
    let node = index as usize;
    if visited[node] { return false; }
    visited[node] = true;
    let offset = 1 + 3 * node;
    let value = values[offset];
    let left = values[offset + 1];
    let right = values[offset + 2];
    if value < i32::MIN as i64 || value > i32::MAX as i64 || left < -1 || right < -1 ||
        left >= node_count as i64 || right >= node_count as i64 { return false; }
    validate_subtree(values, node_count, left, depth + 1, visited) &&
        validate_subtree(values, node_count, right, depth + 1, visited)
}

fn store_i64_little_endian(output: &mut [u8], offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 { output[offset + byte] = (bits >> (8 * byte)) as u8; }
}

fn emit_mirrored_subtree(values: &[i64], index: i64, output: &mut [u8]) {
    if index == -1 { return; }
    let input_offset = 1 + 3 * index as usize;
    let output_offset = 24 * index as usize;
    let left = values[input_offset + 1];
    let right = values[input_offset + 2];
    store_i64_little_endian(output, output_offset, values[input_offset]);
    store_i64_little_endian(output, output_offset + 8, right);
    store_i64_little_endian(output, output_offset + 16, left);
    emit_mirrored_subtree(values, right, output);
    emit_mirrored_subtree(values, left, output);
}

#[no_mangle]
pub extern "C" fn invert_binary_tree(values: *const i64, length: usize,
                                      output: *mut u8, output_capacity: usize) -> i64 {
    if values.is_null() || length < 1 || (length - 1) % 3 != 0 ||
        length > 1 + 3 * MAX_NODE_COUNT { return -1; }
    let input = unsafe { std::slice::from_raw_parts(values, length) };
    let node_count = (length - 1) / 3;
    let root = input[0];
    if node_count == 0 { return if root == -1 { 0 } else { -1 }; }
    if root < 0 || root as usize >= node_count { return -1; }
    let mut visited = [false; MAX_NODE_COUNT];
    if !validate_subtree(input, node_count, root, 1, &mut visited) ||
        visited[..node_count].iter().any(|&seen| !seen) { return -1; }
    let required = 24 * node_count;
    if output.is_null() || output_capacity < required { return -2; }
    let encoded = unsafe { std::slice::from_raw_parts_mut(output, required) };
    emit_mirrored_subtree(input, root, encoded);
    node_count as i64
}
