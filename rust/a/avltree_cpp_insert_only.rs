const MAX_NODES: usize = 256;

fn avl_height(root: i32, left: &[i32; MAX_NODES], right: &[i32; MAX_NODES]) -> i32 {
    if root < 0 { return 0; }
    let index = root as usize;
    1 + avl_height(left[index], left, right).max(avl_height(right[index], left, right))
}

fn avl_balance(root: i32, left: &[i32; MAX_NODES], right: &[i32; MAX_NODES]) -> i32 {
    let index = root as usize;
    avl_height(left[index], left, right) - avl_height(right[index], left, right)
}

fn rotate_right(root: i32, left: &mut [i32; MAX_NODES], right: &mut [i32; MAX_NODES]) -> i32 {
    let root_index = root as usize;
    let pivot = left[root_index];
    let pivot_index = pivot as usize;
    let moved = right[pivot_index];
    right[pivot_index] = root;
    left[root_index] = moved;
    pivot
}

fn rotate_left(root: i32, left: &mut [i32; MAX_NODES], right: &mut [i32; MAX_NODES]) -> i32 {
    let root_index = root as usize;
    let pivot = right[root_index];
    let pivot_index = pivot as usize;
    let moved = left[pivot_index];
    left[pivot_index] = root;
    right[root_index] = moved;
    pivot
}

fn insert_node(
    root: i32,
    key: i32,
    keys: &mut [i32; MAX_NODES],
    left: &mut [i32; MAX_NODES],
    right: &mut [i32; MAX_NODES],
    next_node: &mut usize,
) -> i32 {
    if root < 0 {
        let node = *next_node;
        *next_node += 1;
        keys[node] = key;
        left[node] = -1;
        right[node] = -1;
        return node as i32;
    }
    let root_index = root as usize;
    if key < keys[root_index] {
        let child = left[root_index];
        let updated = insert_node(child, key, keys, left, right, next_node);
        left[root_index] = updated;
    } else {
        let child = right[root_index];
        let updated = insert_node(child, key, keys, left, right, next_node);
        right[root_index] = updated;
    }

    let balance = avl_balance(root, left, right);
    if balance > 1 {
        if avl_balance(left[root_index], left, right) < 0 {
            let child = left[root_index];
            let updated = rotate_left(child, left, right);
            left[root_index] = updated;
        }
        return rotate_right(root, left, right);
    }
    if balance < -1 {
        if avl_balance(right[root_index], left, right) > 0 {
            let child = right[root_index];
            let updated = rotate_right(child, left, right);
            right[root_index] = updated;
        }
        return rotate_left(root, left, right);
    }
    root
}

fn store_i32_le(output: &mut [u8], position: usize, value: i32) {
    let bytes = value.to_le_bytes();
    output[position * 4..position * 4 + 4].copy_from_slice(&bytes);
}

fn emit_inorder(
    root: i32,
    keys: &[i32; MAX_NODES],
    left: &[i32; MAX_NODES],
    right: &[i32; MAX_NODES],
    output: &mut [u8],
    position: &mut usize,
) {
    if root < 0 { return; }
    let index = root as usize;
    emit_inorder(left[index], keys, left, right, output, position);
    store_i32_le(output, *position, keys[index]);
    *position += 1;
    emit_inorder(right[index], keys, left, right, output, position);
}

#[no_mangle]
pub unsafe extern "C" fn avltree_cpp_insert_only(
    input: *const i64,
    length: usize,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if input.is_null() || length < 2 || length > MAX_NODES + 1 { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    if !(1..=MAX_NODES as i64).contains(&values[0]) { return -1; }
    let count = values[0] as usize;
    if length != count + 1 { return -1; }
    for index in 0..count {
        let key = values[index + 1];
        if key < i32::MIN as i64 || key > i32::MAX as i64 { return -1; }
        if values[1..index + 1].contains(&key) { return -1; }
    }
    let required = count * 4;
    if output.is_null() || output_capacity < required { return -2; }

    let mut keys = [0_i32; MAX_NODES];
    let mut left = [-1_i32; MAX_NODES];
    let mut right = [-1_i32; MAX_NODES];
    let mut next_node = 0_usize;
    let mut root = -1_i32;
    for index in 0..count {
        root = insert_node(root, values[index + 1] as i32, &mut keys, &mut left, &mut right, &mut next_node);
    }
    let output = std::slice::from_raw_parts_mut(output, required);
    let mut position = 0;
    emit_inorder(root, &keys, &left, &right, output, &mut position);
    count as i64
}
