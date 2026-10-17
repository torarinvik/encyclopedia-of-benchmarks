const MAX_LENGTH: usize = 64;
const MAX_OPERATIONS: usize = 20;
const MAX_TREE_NODES: usize = 128;
const MAX_VALID_INPUT_LENGTH: usize = 146;
const MAX_PARSEABLE_INPUT_LENGTH: usize = 147;
const CHECKSUM_OFFSET: i64 = 67_108_865;

fn apply_update(tree: &mut [i64; MAX_TREE_NODES], operand: &mut [i64; MAX_TREE_NODES],
                query_left: usize, query_right: usize, node: usize,
                left: usize, right: usize, factor: i64) {
    if query_left <= left && right <= query_right {
        operand[node] *= factor;
        tree[node] *= factor;
        return;
    }
    if query_right <= left || right <= query_left { return; }
    let middle = left + (right - left) / 2;
    apply_update(tree, operand, query_left, query_right, node * 2, left, middle, factor);
    apply_update(tree, operand, query_left, query_right, node * 2 + 1, middle, right, factor);
    tree[node] = operand[node] * (tree[node * 2] + tree[node * 2 + 1]);
}

fn query_sum(tree: &[i64; MAX_TREE_NODES], operand: &[i64; MAX_TREE_NODES],
             query_left: usize, query_right: usize, node: usize,
             left: usize, right: usize) -> i64 {
    if query_left <= left && right <= query_right { return tree[node]; }
    if query_right <= left || right <= query_left { return 0; }
    let middle = left + (right - left) / 2;
    operand[node] * (query_sum(tree, operand, query_left, query_right, node * 2, left, middle)
        + query_sum(tree, operand, query_left, query_right, node * 2 + 1, middle, right))
}

#[no_mangle]
pub unsafe extern "C" fn segment_tree_apply_benchmark(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 2 || length > MAX_PARSEABLE_INPUT_LENGTH { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    if values[0] < 1 || values[0] > MAX_LENGTH as i64 { return -1; }
    let n = values[0] as usize;
    if length < n + 2 { return -1; }
    let operation_count_value = values[n + 1];
    if operation_count_value < 0 || operation_count_value > MAX_OPERATIONS as i64 { return -1; }
    let operation_count = operation_count_value as usize;
    if length != n + 2 + 4 * operation_count || length > MAX_VALID_INPUT_LENGTH { return -1; }

    let mut base = 1;
    while base < n { base <<= 1; }
    let mut tree = [0_i64; MAX_TREE_NODES];
    let mut operand = [1_i64; MAX_TREE_NODES];
    for index in 0..n {
        let value = values[index + 1];
        if !(-1..=1).contains(&value) { return -1; }
        tree[base + index] = value;
    }
    for node in (1..base).rev() { tree[node] = tree[node * 2] + tree[node * 2 + 1]; }

    let mut checksum = 0_i64;
    for operation in 0..operation_count {
        let offset = n + 2 + 4 * operation;
        let opcode = values[offset];
        let left = values[offset + 1];
        let right = values[offset + 2];
        let argument = values[offset + 3];
        if left < 0 || left > right || right >= n as i64 { return -1; }
        let query_left = left as usize;
        let query_right = right as usize + 1;
        if opcode == 0 {
            if !(-2..=2).contains(&argument) { return -1; }
            apply_update(&mut tree, &mut operand, query_left, query_right, 1, 0, base, argument);
        } else if opcode == 1 {
            if argument != 0 { return -1; }
            let result = query_sum(&tree, &operand, query_left, query_right, 1, 0, base);
            checksum += (operation as i64 + 1) * (result + CHECKSUM_OFFSET);
        } else { return -1; }
    }
    checksum
}
