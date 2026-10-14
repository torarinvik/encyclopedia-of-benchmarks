const MAX_ITEMS: usize = 256;
const MAX_OPERATIONS: usize = 512;
const MAX_INPUT_VALUES: usize = 2 + 3 * MAX_OPERATIONS;
const VALUE_LIMIT: i64 = 1_000_000;
const QUERY_OFFSET: i64 = 131_072_000_001;
const FINAL_OFFSET: i64 = 512_000_001;

fn lowbit(index: usize) -> usize { index & (!index + 1) }

fn prefix_sum(tree: &[i64; MAX_ITEMS + 1], mut count: usize) -> i64 {
    let mut sum = 0i64;
    while count > 0 {
        sum += tree[count];
        count -= lowbit(count);
    }
    sum
}

#[no_mangle]
pub unsafe extern "C" fn fenwick_tree_benchmark(values: *const i64, length: usize) -> i64 {
    if length < 2 || length > MAX_INPUT_VALUES { return -1; }
    let item_count_value = *values;
    let operation_count_value = *values.add(1);
    if !(1..=MAX_ITEMS as i64).contains(&item_count_value) ||
        !(0..=MAX_OPERATIONS as i64).contains(&operation_count_value) { return -1; }
    let item_count = item_count_value as usize;
    let operation_count = operation_count_value as usize;
    if length != 2 + 3 * operation_count { return -1; }
    for operation in 0..operation_count {
        let position = 2 + 3 * operation;
        let opcode = *values.add(position);
        let first = *values.add(position + 1);
        let second = *values.add(position + 2);
        if opcode == 0 {
            if first < 0 || first >= item_count_value || second < -VALUE_LIMIT || second > VALUE_LIMIT { return -1; }
        } else if opcode == 1 {
            if first < 0 || second < first || second >= item_count_value { return -1; }
        } else { return -1; }
    }

    let mut data = [0i64; MAX_ITEMS];
    let mut tree = [0i64; MAX_ITEMS + 1];
    let mut checksum = 0i64;
    for operation in 0..operation_count {
        let position = 2 + 3 * operation;
        let opcode = *values.add(position);
        let first = *values.add(position + 1) as usize;
        let second = *values.add(position + 2);
        if opcode == 0 {
            data[first] += second;
            let mut index = first + 1;
            while index <= item_count {
                tree[index] += second;
                index += lowbit(index);
            }
        } else {
            let right = second as usize;
            let result = prefix_sum(&tree, right + 1) - prefix_sum(&tree, first);
            checksum += (operation as i64 + 1) * (result + QUERY_OFFSET);
        }
    }
    for i in 0..item_count {
        checksum += (operation_count as i64 + i as i64 + 1) * (data[i] + FINAL_OFFSET);
    }
    checksum
}
