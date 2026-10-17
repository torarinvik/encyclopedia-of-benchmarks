const MAX_NODE_COUNT: usize = 63;
const MAX_PARSEABLE_INPUT_LENGTH: usize = 65;

fn store_i32_le(output: *mut u8, offset: usize, value: i32) {
    let bits = value as u32;
    for byte in 0..4 {
        unsafe { *output.add(offset + byte) = (bits >> (byte * 8)) as u8; }
    }
}

/// Bounded Morris inorder traversal over a complete level-order tree.
#[no_mangle]
pub unsafe extern "C" fn morrisinorder(
    values: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if values.is_null() || length < 1 || length > MAX_PARSEABLE_INPUT_LENGTH { return -1; }
    let input = std::slice::from_raw_parts(values, length);
    let raw_count = input[0];
    if raw_count < 0 || raw_count > MAX_NODE_COUNT as i64 { return -1; }
    let count = raw_count as usize;
    if length != count + 1 { return -1; }
    if input[1..].iter().any(|&node| node < i32::MIN as i64 || node > i32::MAX as i64) {
        return -1;
    }

    let byte_count = 4 * count;
    if output.is_null() || capacity < byte_count { return -2; }

    let mut left_nodes = [-1i32; MAX_NODE_COUNT];
    let mut right_nodes = [-1i32; MAX_NODE_COUNT];
    for index in 0..count {
        let left_index = 2 * index + 1;
        let right_index = 2 * index + 2;
        if left_index < count { left_nodes[index] = left_index as i32; }
        if right_index < count { right_nodes[index] = right_index as i32; }
    }

    let mut current = if count == 0 { -1 } else { 0 };
    let mut written = 0;
    while current >= 0 {
        let current_index = current as usize;
        if left_nodes[current_index] < 0 {
            store_i32_le(output, written * 4, input[current_index + 1] as i32);
            written += 1;
            current = right_nodes[current_index];
        } else {
            let mut predecessor = left_nodes[current_index] as usize;
            while right_nodes[predecessor] >= 0 && right_nodes[predecessor] != current {
                predecessor = right_nodes[predecessor] as usize;
            }
            if right_nodes[predecessor] < 0 {
                right_nodes[predecessor] = current;
                current = left_nodes[current_index];
            } else {
                right_nodes[predecessor] = -1;
                store_i32_le(output, written * 4, input[current_index + 1] as i32);
                written += 1;
                current = right_nodes[current_index];
            }
        }
    }
    byte_count as i64
}
