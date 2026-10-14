const MAX_ITEMS: usize = 256;
const MAX_OPERATIONS: usize = 512;
const MAX_INPUT_VALUES: usize = 2 + 3 * MAX_OPERATIONS;
const OBSERVED_OFFSET: i64 = 1_000_003;

fn find_root(parent: &mut [usize; MAX_ITEMS], mut item: usize) -> usize {
    while parent[item] != item {
        parent[item] = parent[parent[item]];
        item = parent[item];
    }
    item
}

#[no_mangle]
pub unsafe extern "C" fn union_find_benchmark(values: *const i64, length: usize) -> i64 {
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
        if opcode == 0 || opcode == 1 {
            if first < 0 || first >= item_count_value || second < 0 || second >= item_count_value { return -1; }
        } else if opcode == 2 {
            if first != 0 || second != 0 { return -1; }
        } else { return -1; }
    }

    let mut parent = [0usize; MAX_ITEMS];
    let mut set_size = [0usize; MAX_ITEMS];
    for i in 0..item_count { parent[i] = i; set_size[i] = 1; }
    let mut components = item_count;
    let mut connected_pairs = 0i64;
    let mut checksum = 0i64;
    for operation in 0..operation_count {
        let position = 2 + 3 * operation;
        let opcode = *values.add(position);
        let first = *values.add(position + 1) as usize;
        let second = *values.add(position + 2) as usize;
        let observed: i64;
        if opcode == 0 {
            let first_root = find_root(&mut parent, first);
            let second_root = find_root(&mut parent, second);
            if first_root == second_root {
                observed = 0;
            } else {
                connected_pairs += (set_size[first_root] * set_size[second_root]) as i64;
                if set_size[first_root] < set_size[second_root] {
                    parent[first_root] = second_root;
                    set_size[second_root] += set_size[first_root];
                } else {
                    parent[second_root] = first_root;
                    set_size[first_root] += set_size[second_root];
                }
                components -= 1;
                observed = 1;
            }
        } else if opcode == 1 {
            observed = i64::from(find_root(&mut parent, first) == find_root(&mut parent, second));
        } else {
            observed = components as i64;
        }
        checksum += (operation as i64 + 1) * (observed + OBSERVED_OFFSET);
    }
    checksum + connected_pairs
}
