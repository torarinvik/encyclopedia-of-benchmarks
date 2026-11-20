/// Union-find with circular component-member enumeration.
const MAX_ITEMS: usize = 16;
const MAX_OPERATIONS: usize = 32;
const MAX_INPUT_LENGTH: usize = 99;

fn find_root(parent: &mut [i64; MAX_ITEMS], item: usize) -> usize {
    let mut root = item;
    while parent[root] >= 0 { root = parent[root] as usize; }
    let mut current = item;
    while current != root {
        let next_item = parent[current] as usize;
        parent[current] = root as i64;
        current = next_item;
    }
    root
}

fn component_mask(successor: &[i64; MAX_ITEMS], start: usize) -> i64 {
    let mut mask = 0i64;
    let mut item = start;
    loop {
        mask |= 1i64 << item;
        item = successor[item] as usize;
        if item == start { break; }
    }
    mask
}

#[no_mangle]
pub extern "C" fn union_find_enumerate(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT_LENGTH { return -1; }
    let input = unsafe { std::slice::from_raw_parts(input, length) };
    let item_count_value = input[0];
    let operation_count_value = input[1];
    if !(1..=MAX_ITEMS as i64).contains(&item_count_value)
        || !(0..=MAX_OPERATIONS as i64).contains(&operation_count_value) { return -1; }
    let item_count = item_count_value as usize;
    let operation_count = operation_count_value as usize;
    if length != 2 + 3 * operation_count { return -1; }

    for operation in 0..operation_count {
        let position = 2 + 3 * operation;
        let (opcode, first, second) = (input[position], input[position + 1], input[position + 2]);
        if opcode == 0 {
            if !(0..item_count_value).contains(&first) || !(0..item_count_value).contains(&second) { return -1; }
        } else if opcode == 1 {
            if !(0..item_count_value).contains(&first) || second != 0 { return -1; }
        } else { return -1; }
    }

    let mut parent = [-1i64; MAX_ITEMS];
    let mut successor = [0i64; MAX_ITEMS];
    for item in 0..item_count { successor[item] = item as i64; }
    let mut checksum = 0i64;
    for operation in 0..operation_count {
        let position = 2 + 3 * operation;
        let opcode = input[position];
        let first = input[position + 1] as usize;
        let observed = if opcode == 0 {
            let mut left = find_root(&mut parent, first);
            let mut right = find_root(&mut parent, input[position + 2] as usize);
            if left == right { 0 } else {
                if parent[left] > parent[right] { std::mem::swap(&mut left, &mut right); }
                parent[left] += parent[right];
                parent[right] = left as i64;
                successor.swap(left, right);
                1
            }
        } else {
            component_mask(&successor, first)
        };
        checksum += (operation as i64 + 1) * (observed + 1);
    }
    checksum
}
