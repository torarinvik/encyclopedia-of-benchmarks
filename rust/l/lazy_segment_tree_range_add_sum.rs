const MAX_ITEMS: usize = 256;
const MAX_OPERATIONS: usize = 512;
const MAX_INPUT_LENGTH: usize = 2306;
const VALUE_LIMIT: i64 = 1_000_000;
const QUERY_OFFSET: i64 = 131_328_000_001;
const TREE_SIZE: usize = 2 * MAX_ITEMS;

fn apply(tree: &mut [i64; TREE_SIZE], pending: &mut [i64; TREE_SIZE],
         node: usize, segment_length: usize, delta: i64) {
    tree[node] += delta * segment_length as i64;
    pending[node] += delta;
}

fn push(tree: &mut [i64; TREE_SIZE], pending: &mut [i64; TREE_SIZE],
        node: usize, segment_length: usize) {
    if segment_length > 1 && pending[node] != 0 {
        let child_length = segment_length / 2;
        apply(tree, pending, 2 * node, child_length, pending[node]);
        apply(tree, pending, 2 * node + 1, child_length, pending[node]);
        pending[node] = 0;
    }
}

fn range_add(tree: &mut [i64; TREE_SIZE], pending: &mut [i64; TREE_SIZE],
             node: usize, low: usize, high: usize, query_low: usize,
             query_high: usize, delta: i64) {
    if query_low <= low && high <= query_high {
        apply(tree, pending, node, high - low, delta);
        return;
    }
    push(tree, pending, node, high - low);
    let middle = (low + high) / 2;
    if query_low < middle {
        range_add(tree, pending, 2 * node, low, middle, query_low, query_high, delta);
    }
    if query_high > middle {
        range_add(tree, pending, 2 * node + 1, middle, high, query_low, query_high, delta);
    }
    tree[node] = tree[2 * node] + tree[2 * node + 1];
}

fn range_sum(tree: &mut [i64; TREE_SIZE], pending: &mut [i64; TREE_SIZE],
             node: usize, low: usize, high: usize, query_low: usize,
             query_high: usize) -> i64 {
    if query_low <= low && high <= query_high { return tree[node]; }
    push(tree, pending, node, high - low);
    let middle = (low + high) / 2;
    let mut result = 0;
    if query_low < middle {
        result += range_sum(tree, pending, 2 * node, low, middle, query_low, query_high);
    }
    if query_high > middle {
        result += range_sum(tree, pending, 2 * node + 1, middle, high, query_low, query_high);
    }
    result
}

#[no_mangle]
pub unsafe extern "C" fn lazy_segment_tree_range_add_sum(values: *const i64, length: usize) -> i64 {
    if values.is_null() || length < 3 || length > MAX_INPUT_LENGTH { return -1; }
    let values = unsafe { std::slice::from_raw_parts(values, length) };
    let item_count_value = values[0];
    if item_count_value < 1 || item_count_value > MAX_ITEMS as i64 { return -1; }
    let item_count = item_count_value as usize;
    if length < item_count + 2 { return -1; }
    let operation_count_value = values[item_count + 1];
    if operation_count_value < 0 || operation_count_value > MAX_OPERATIONS as i64 { return -1; }
    let operation_count = operation_count_value as usize;
    if length != item_count + 2 + 4 * operation_count { return -1; }

    for value in &values[1..=item_count] {
        if *value < -VALUE_LIMIT || *value > VALUE_LIMIT { return -1; }
    }
    for operation in 0..operation_count {
        let position = item_count + 2 + 4 * operation;
        let opcode = values[position];
        let left = values[position + 1];
        let right = values[position + 2];
        let delta = values[position + 3];
        if left < 0 || left >= right || right > item_count_value { return -1; }
        if opcode == 0 {
            if delta < -VALUE_LIMIT || delta > VALUE_LIMIT { return -1; }
        } else if opcode == 1 {
            if delta != 0 { return -1; }
        } else { return -1; }
    }

    let mut base = 1;
    while base < item_count { base *= 2; }
    let mut tree = [0_i64; TREE_SIZE];
    let mut pending = [0_i64; TREE_SIZE];
    for index in 0..item_count { tree[base + index] = values[index + 1]; }
    let mut node = base;
    while node > 1 {
        node -= 1;
        tree[node] = tree[2 * node] + tree[2 * node + 1];
    }

    let mut checksum = 0_i64;
    for operation in 0..operation_count {
        let position = item_count + 2 + 4 * operation;
        let left = values[position + 1] as usize;
        let right = values[position + 2] as usize;
        if values[position] == 0 {
            range_add(&mut tree, &mut pending, 1, 0, base, left, right, values[position + 3]);
        } else {
            checksum += range_sum(&mut tree, &mut pending, 1, 0, base, left, right) + QUERY_OFFSET;
        }
    }
    checksum
}
