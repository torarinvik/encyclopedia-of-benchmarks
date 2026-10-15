/// Follow the unique BST branch until the target node or an empty child.
const MAX_NODE_COUNT: usize = 5000;
const MAX_VALUE: i64 = 10_000_000;

#[no_mangle]
pub unsafe extern "C" fn search_in_bst(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 3 { return -1; }
    let count_value = *input;
    let root = *input.add(1);
    let target = *input.add(2);
    if count_value < 0 || count_value as u64 > MAX_NODE_COUNT as u64 ||
        length != 3 + 3 * count_value as usize || target < 1 || target > MAX_VALUE { return -1; }
    let count = count_value as usize;
    if count == 0 { return -1; }
    if root < 0 || root as u64 >= count as u64 { return -1; }
    let mut node = root;
    while node != -1 {
        if node < 0 || node as u64 >= count as u64 { return -1; }
        let offset = 3 + 3 * node as usize;
        let value = *input.add(offset);
        let left = *input.add(offset + 1);
        let right = *input.add(offset + 2);
        if value < 1 || value > MAX_VALUE || left < -1 || right < -1 ||
            (left >= 0 && left as u64 >= count as u64) ||
            (right >= 0 && right as u64 >= count as u64) { return -1; }
        if value == target { return node; }
        node = if target < value { left } else { right };
    }
    -1
}
