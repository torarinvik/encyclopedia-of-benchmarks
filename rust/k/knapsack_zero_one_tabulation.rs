/// Bottom-up 0/1 knapsack using one row and descending capacities.
#[no_mangle]
pub extern "C" fn knapsack_zero_one_tabulation(packed: *const i64, length: usize) -> i64 {
    if packed.is_null() || !(2..=258).contains(&length) {
        return -1;
    }
    let packed = unsafe { std::slice::from_raw_parts(packed, length) };
    if !(0..=512).contains(&packed[0]) || !(0..=128).contains(&packed[1]) {
        return -1;
    }
    let capacity = packed[0] as usize;
    let item_count = packed[1] as usize;
    if length != 2 + 2 * item_count {
        return -1;
    }
    for item in 0..item_count {
        let weight = packed[2 + 2 * item];
        let value = packed[3 + 2 * item];
        if !(1..=4096).contains(&weight) || !(0..=1_000_000_000).contains(&value) {
            return -1;
        }
    }

    let mut dp = [0_i64; 513];
    let width = capacity + 1;
    let steps = item_count * width;
    for step in 0..steps {
        let item = step / width;
        let current_capacity = capacity - step % width;
        let weight = packed[2 + 2 * item] as usize;
        let value = packed[3 + 2 * item];
        if weight <= current_capacity {
            let candidate = dp[current_capacity - weight] + value;
            if candidate > dp[current_capacity] {
                dp[current_capacity] = candidate;
            }
        }
    }
    dp[capacity]
}
