const INVALID_RESULT: i64 = -1;

fn solve(packed: &[i64], item_count: usize, capacity: i64) -> i64 {
    if item_count == 0 || capacity == 0 {
        return 0;
    }
    let weight = packed[2 + 2 * (item_count - 1)];
    let value = packed[3 + 2 * (item_count - 1)];
    if weight > capacity {
        return solve(packed, item_count - 1, capacity);
    }
    let excluded = solve(packed, item_count - 1, capacity);
    let included = value + solve(packed, item_count - 1, capacity - weight);
    excluded.max(included)
}

#[no_mangle]
pub unsafe extern "C" fn brute_force_knapsack(packed: *const i64, length: usize) -> i64 {
    if packed.is_null() || length < 2 || length > 30 {
        return INVALID_RESULT;
    }
    let values = std::slice::from_raw_parts(packed, length);
    let capacity = values[0];
    let count_value = values[1];
    if !(0..=512).contains(&capacity) || !(0..=14).contains(&count_value) {
        return INVALID_RESULT;
    }
    let item_count = count_value as usize;
    if length != 2 + 2 * item_count {
        return INVALID_RESULT;
    }
    for item in 0..item_count {
        let weight = values[2 + 2 * item];
        let value = values[3 + 2 * item];
        if !(1..=4096).contains(&weight) || !(0..=100_000_000).contains(&value) {
            return INVALID_RESULT;
        }
    }
    solve(values, item_count, capacity)
}
