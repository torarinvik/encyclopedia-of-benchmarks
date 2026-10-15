const MAX_NODES: usize = 63;
const MAX_OUTPUT: usize = 6 * MAX_NODES + 1;

#[no_mangle]
pub unsafe extern "C" fn create_binary_tree_from_inorder_preorder(values: *const i64,
    length: usize, output: *mut u8, output_capacity: usize) -> i64 {
    if values.is_null() || length < 1 { return -1; }
    let input = std::slice::from_raw_parts(values, length);
    if input[0] < 0 || input[0] as usize > MAX_NODES { return -1; }
    let count = input[0] as usize;
    if length != 1 + 2 * count { return -1; }
    let preorder = &input[1..1 + count];
    let inorder = &input[1 + count..];
    for i in 0..count {
        if preorder[i] < i32::MIN as i64 || preorder[i] > i32::MAX as i64 ||
            inorder[i] < i32::MIN as i64 || inorder[i] > i32::MAX as i64 { return -1; }
        if (0..i).any(|j| preorder[i] == preorder[j] || inorder[i] == inorder[j]) ||
            inorder.iter().filter(|&&v| v == preorder[i]).count() != 1 { return -1; }
    }
    let mut left = vec![-1_i32; count];
    let mut right = vec![-1_i32; count];
    let mut tasks: Vec<(usize, usize, usize)> = Vec::new();
    if count > 0 { tasks.push((0, 0, count)); }
    while let Some((pre_start, in_start, size)) = tasks.pop() {
        if size == 0 || pre_start + size > count || in_start + size > count { return -1; }
        let Some(relative) = inorder[in_start..in_start + size].iter().position(|&v| v == preorder[pre_start]) else { return -1; };
        let root_position = in_start + relative;
        let left_size = relative;
        let right_size = size - left_size - 1;
        if left_size > 0 { left[pre_start] = (pre_start + 1) as i32; }
        if right_size > 0 { right[pre_start] = (pre_start + left_size + 1) as i32; }
        if right_size > 0 { tasks.push((pre_start + left_size + 1, root_position + 1, right_size)); }
        if left_size > 0 { tasks.push((pre_start + 1, in_start, left_size)); }
    }
    let required = 6 * count + 1;
    if output.is_null() || output_capacity < required { return -2; }
    let mut encoded = Vec::<u8>::with_capacity(required);
    let mut pending = vec![if count == 0 { -1_i32 } else { 0_i32 }];
    while let Some(node) = pending.pop() {
        if node < 0 { encoded.push(0); continue; }
        let node = node as usize;
        let value = preorder[node] as i32 as u32;
        encoded.push(1);
        for byte in 0..4 { encoded.push((value >> (8 * byte)) as u8); }
        pending.push(right[node]); pending.push(left[node]);
    }
    std::ptr::copy_nonoverlapping(encoded.as_ptr(), output, encoded.len());
    count as i64
}
