const MAX_ITEMS: usize = 256;
const MAX_OPERATIONS: usize = 512;
const MAX_INPUT_VALUES: usize = 2 + 3 * MAX_OPERATIONS;
const VALUE_LIMIT: i64 = 1_000_000;
const QUERY_OFFSET: i64 = 131_072_000_001;
const FINAL_OFFSET: i64 = 512_000_001;

fn lowbit(index: usize) -> usize { index & (!index + 1) }
fn prefix_sum(tree: &[i32; MAX_ITEMS + 2], mut count: usize) -> i32 {
    let mut sum = 0i32;
    while count > 0 { sum += tree[count]; count -= lowbit(count); }
    sum
}

#[no_mangle]
pub unsafe extern "C" fn binary_indexed_tree(values: *const i64, length: usize) -> i64 {
    if values.is_null() || length < 2 || length > MAX_INPUT_VALUES { return -1; }
    let n_value = *values;
    let op_value = *values.add(1);
    if n_value < 2 || n_value > MAX_ITEMS as i64 || (n_value & (n_value - 1)) != 0 || op_value < 0 || op_value > MAX_OPERATIONS as i64 { return -1; }
    let n = n_value as usize;
    let operations = op_value as usize;
    if length != 2 + 3 * operations { return -1; }
    for op in 0..operations {
        let at = 2 + 3 * op;
        let code = *values.add(at);
        let first = *values.add(at + 1);
        let second = *values.add(at + 2);
        if code == 0 { if first < 0 || first >= n_value || second < -VALUE_LIMIT || second > VALUE_LIMIT { return -1; } }
        else if code == 1 { if first < 0 || second < first || second >= n_value { return -1; } }
        else { return -1; }
    }
    let mut data = [0i32; MAX_ITEMS];
    let mut tree = [0i32; MAX_ITEMS + 2];
    let mut checksum = 0i64;
    for op in 0..operations {
        let at = 2 + 3 * op;
        let code = *values.add(at);
        let first = *values.add(at + 1) as usize;
        let second = *values.add(at + 2) as i32;
        if code == 0 {
            data[first] += second;
            let mut start = first + 1;
            while start <= n + 1 { tree[start] += second; start += lowbit(start); }
        } else {
            let result = prefix_sum(&tree, second as usize + 1) - prefix_sum(&tree, first);
            checksum += (op as i64 + 1) * (result as i64 + QUERY_OFFSET);
        }
    }
    for i in 0..n { checksum += (operations as i64 + i as i64 + 1) * (data[i] as i64 + FINAL_OFFSET); }
    checksum
}
