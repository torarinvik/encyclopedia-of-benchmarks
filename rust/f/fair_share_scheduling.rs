unsafe fn store_i64_le(output: *mut u8, position: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 {
        *output.add(position + byte) = (bits >> (byte * 8)) as u8;
    }
}

#[no_mangle]
pub unsafe extern "C" fn fair_share_scheduling(
    values: *const i64, length: usize, output: *mut u8, output_capacity: usize,
) -> i64 {
    if values.is_null() || !(3..=323).contains(&length) { return -2; }
    let user_value = *values;
    let task_value = *values.add(1);
    let resources = *values.add(2);
    if !(0..=64).contains(&user_value) || !(0..=128).contains(&task_value)
        || !(0..=1_000_000).contains(&resources) { return -2; }
    let user_count = user_value as usize;
    let task_count = task_value as usize;
    if length != 3 + user_count + 2 * task_count { return -2; }

    let mut ids = [0_i64; 64];
    let mut weights = [0_i64; 64];
    let mut order = [0_usize; 64];
    for user in 0..user_count {
        let id = *values.add(3 + user);
        if !(0..=63).contains(&id) || ids[..user].contains(&id) { return -2; }
        ids[user] = id;
        order[user] = user;
    }
    let task_start = 3 + user_count;
    for task in 0..task_count {
        let owner = *values.add(task_start + 2 * task);
        let weight = *values.add(task_start + 2 * task + 1);
        if !(0..=63).contains(&owner) || !(0..=1_000_000).contains(&weight) { return -2; }
        for user in 0..user_count {
            if ids[user] == owner {
                weights[user] += weight;
                break;
            }
        }
    }
    for i in 1..user_count {
        let key = order[i];
        let mut j = i;
        while j > 0 && ids[order[j - 1]] > ids[key] {
            order[j] = order[j - 1];
            j -= 1;
        }
        order[j] = key;
    }
    let total_weight: i64 = weights[..user_count].iter().sum();
    let required = user_count * 24;
    if output_capacity < required || (required != 0 && output.is_null()) { return -2; }
    for position in 0..user_count {
        let user = order[position];
        let allocation = if total_weight == 0 { 0 } else { weights[user] * resources / total_weight };
        store_i64_le(output, position * 24, ids[user]);
        store_i64_le(output, position * 24 + 8, weights[user]);
        store_i64_le(output, position * 24 + 16, allocation);
    }
    user_count as i64
}
