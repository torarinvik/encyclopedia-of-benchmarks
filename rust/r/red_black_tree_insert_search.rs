const MAX_OPERATIONS: usize = 128;
const INVALID_RESULT: i64 = -1;
const CAPACITY_RESULT: i64 = -2;

#[derive(Clone, Copy, Default)]
struct Node { key: i64, left: usize, right: usize, red: bool }

fn is_red(tree: &[Node; MAX_OPERATIONS + 1], node: usize) -> bool { node != 0 && tree[node].red }
fn flip_colors(tree: &mut [Node; MAX_OPERATIONS + 1], node: usize) {
    tree[node].red = !tree[node].red;
    let left = tree[node].left; let right = tree[node].right;
    tree[left].red = !tree[left].red; tree[right].red = !tree[right].red;
}
fn rotate_left(tree: &mut [Node; MAX_OPERATIONS + 1], node: usize) -> usize {
    let pivot = tree[node].right; let left = tree[pivot].left;
    tree[node].right = left; tree[pivot].left = node;
    tree[pivot].red = tree[node].red; tree[node].red = true; pivot
}
fn rotate_right(tree: &mut [Node; MAX_OPERATIONS + 1], node: usize) -> usize {
    let pivot = tree[node].left; let right = tree[pivot].right;
    tree[node].left = right; tree[pivot].right = node;
    tree[pivot].red = tree[node].red; tree[node].red = true; pivot
}
fn insert_node(tree: &mut [Node; MAX_OPERATIONS + 1], node: usize, key: i64, next: &mut usize) -> usize {
    if node == 0 { let created = *next; *next += 1; tree[created] = Node { key, left: 0, right: 0, red: true }; return created; }
    if is_red(tree, tree[node].left) && is_red(tree, tree[node].right) { flip_colors(tree, node); }
    if key == tree[node].key { tree[node].key = key; }
    else if key < tree[node].key { let child = insert_node(tree, tree[node].left, key, next); tree[node].left = child; }
    else { let child = insert_node(tree, tree[node].right, key, next); tree[node].right = child; }
    if is_red(tree, tree[node].right) && !is_red(tree, tree[node].left) { return rotate_left(tree, node); }
    if is_red(tree, tree[node].left) && is_red(tree, tree[tree[node].left].left) { return rotate_right(tree, node); }
    node
}
fn find_node(tree: &[Node; MAX_OPERATIONS + 1], mut node: usize, key: i64) -> usize {
    while node != 0 {
        if key < tree[node].key { node = tree[node].left; }
        else if key > tree[node].key { node = tree[node].right; }
        else { return node; }
    }
    0
}
fn insertion_sort(values: &mut [i64; MAX_OPERATIONS], count: usize) {
    for index in 1..count { let value = values[index]; let mut position = index;
        while position > 0 && values[position - 1] > value { values[position] = values[position - 1]; position -= 1; }
        values[position] = value;
    }
}
fn put_i64(output: &mut [u8], offset: usize, value: i64) { output[offset..offset + 8].copy_from_slice(&value.to_le_bytes()); }

#[no_mangle]
pub unsafe extern "C" fn red_black_tree_insert_search(input: *const i64, length: usize, output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 1 { return INVALID_RESULT; }
    let values = std::slice::from_raw_parts(input, length);
    if values[0] < 0 || values[0] > MAX_OPERATIONS as i64 || length != 1 + 2 * values[0] as usize { return INVALID_RESULT; }
    let operation_count = values[0] as usize;
    for op in 0..operation_count {
        let opcode = values[1 + 2 * op]; let key = values[2 + 2 * op];
        if (opcode != 0 && opcode != 1) || key < i32::MIN as i64 || key > i32::MAX as i64 { return INVALID_RESULT; }
    }
    let mut tree = [Node::default(); MAX_OPERATIONS + 1];
    let mut keys = [0i64; MAX_OPERATIONS]; let mut search_results = [0i64; MAX_OPERATIONS];
    let mut root = 0usize; let mut next = 1usize; let mut key_count = 0usize; let mut search_count = 0usize;
    for op in 0..operation_count {
        let opcode = values[1 + 2 * op]; let key = values[2 + 2 * op];
        if opcode == 0 {
            if find_node(&tree, root, key) != 0 { return INVALID_RESULT; }
            root = insert_node(&mut tree, root, key, &mut next); tree[root].red = false;
            keys[key_count] = key; key_count += 1;
        } else { search_results[search_count] = if find_node(&tree, root, key) != 0 { 1 } else { 0 }; search_count += 1; }
    }
    insertion_sort(&mut keys, key_count);
    let required = (2 + key_count + search_count) * 8;
    if output.is_null() || capacity < required { return CAPACITY_RESULT; }
    let out = std::slice::from_raw_parts_mut(output, required);
    let mut offset = 0;
    put_i64(out, offset, key_count as i64); offset += 8;
    for value in keys[..key_count].iter() { put_i64(out, offset, *value); offset += 8; }
    put_i64(out, offset, search_count as i64); offset += 8;
    for value in search_results[..search_count].iter() { put_i64(out, offset, *value); offset += 8; }
    required as i64
}
