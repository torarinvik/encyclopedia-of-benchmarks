const MAX_ITEMS: usize = 256;
const MAX_OPERATIONS: usize = 512;
const MAX_INPUT_VALUES: usize = MAX_ITEMS + 3 + 3 * MAX_OPERATIONS;
const VALUE_LIMIT: i64 = 1_000_000;
const QUERY_OFFSET: i64 = 256_000_001;
const FINAL_OFFSET: i64 = 1_000_001;

fn identity(mode: i64) -> i64 {
    if mode == 1 { VALUE_LIMIT + 1 } else if mode == 2 { -(VALUE_LIMIT + 1) } else { 0 }
}

fn combine(mode: i64, left: i64, right: i64) -> i64 {
    if mode == 1 { left.min(right) } else if mode == 2 { left.max(right) } else { left + right }
}

#[no_mangle]
pub unsafe extern "C" fn segment_tree_benchmark(values: *const i64, length: usize) -> i64 {
    if length < 3 || length > MAX_INPUT_VALUES { return -1; }
    let mode = *values;
    let item_count_value = *values.add(1);
    if !(0..=2).contains(&mode) || item_count_value < 1 || item_count_value > MAX_ITEMS as i64 { return -1; }
    let item_count = item_count_value as usize;
    if length < item_count + 3 { return -1; }
    let operation_count_value = *values.add(item_count + 2);
    if operation_count_value < 0 || operation_count_value > MAX_OPERATIONS as i64 { return -1; }
    let operation_count = operation_count_value as usize;
    if length != item_count + 3 + 3 * operation_count { return -1; }

    let mut data = [0_i64; MAX_ITEMS];
    for i in 0..item_count {
        let value = *values.add(i + 2);
        if !(-VALUE_LIMIT..=VALUE_LIMIT).contains(&value) { return -1; }
        data[i] = value;
    }
    for operation in 0..operation_count {
        let position = item_count + 3 + 3 * operation;
        let opcode = *values.add(position);
        let first = *values.add(position + 1);
        let second = *values.add(position + 2);
        if opcode == 0 {
            if first < 0 || first >= item_count as i64 || !(-VALUE_LIMIT..=VALUE_LIMIT).contains(&second) { return -1; }
        } else if opcode == 1 {
            if first < 0 || second < first || second >= item_count as i64 { return -1; }
        } else { return -1; }
    }

    let mut base = 1;
    while base < item_count { base *= 2; }
    let empty = identity(mode);
    let mut tree = [empty; 2 * MAX_ITEMS];
    for i in 0..item_count { tree[base + i] = data[i]; }
    let mut node = base;
    while node > 1 {
        node -= 1;
        tree[node] = combine(mode, tree[2 * node], tree[2 * node + 1]);
    }

    let mut checksum = 0_i64;
    for operation in 0..operation_count {
        let position = item_count + 3 + 3 * operation;
        let opcode = *values.add(position);
        let first = *values.add(position + 1) as usize;
        if opcode == 0 {
            let value = *values.add(position + 2);
            data[first] = value;
            node = base + first;
            tree[node] = value;
            while node > 1 {
                node /= 2;
                tree[node] = combine(mode, tree[2 * node], tree[2 * node + 1]);
            }
        } else {
            let mut left = base + first;
            let mut right = base + *values.add(position + 2) as usize + 1;
            let mut result = empty;
            while left < right {
                if left & 1 == 1 { result = combine(mode, result, tree[left]); left += 1; }
                if right & 1 == 1 { right -= 1; result = combine(mode, result, tree[right]); }
                left /= 2;
                right /= 2;
            }
            checksum += (operation as i64 + 1) * (result + QUERY_OFFSET);
        }
    }
    for i in 0..item_count {
        checksum += (operation_count as i64 + i as i64 + 1) * (data[i] + FINAL_OFFSET);
    }
    checksum
}
