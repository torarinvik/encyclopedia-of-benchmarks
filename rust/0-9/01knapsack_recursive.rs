const MAX_CAPACITY: i64 = 512;
const MAX_ITEMS: i64 = 16;
const MAX_WEIGHT: i64 = 4096;
const MAX_VALUE: i64 = 1_000_000_000;

unsafe fn solve(packed: *const i64, item_count: i64, capacity: i64) -> i64 {
    if item_count == 0 || capacity == 0 { return 0; }
    let offset = 2 + 2 * (item_count - 1) as usize;
    let weight = *packed.add(offset);
    let value = *packed.add(offset + 1);
    if weight <= capacity {
        let take = value + solve(packed, item_count - 1, capacity - weight);
        let skip = solve(packed, item_count - 1, capacity);
        return take.max(skip);
    }
    solve(packed, item_count - 1, capacity)
}

#[no_mangle]
pub unsafe extern "C" fn knapsack_01_recursive_benchmark(packed: *const i64, length: usize) -> i64 {
    if length < 2 || length > 34 { return -1; }
    let capacity = *packed;
    let item_count = *packed.add(1);
    if capacity < 0 || capacity > MAX_CAPACITY || item_count < 0 || item_count > MAX_ITEMS
        || length != 2 + 2 * item_count as usize { return -1; }
    for item in 0..item_count as usize {
        let offset = 2 + 2 * item;
        let weight = *packed.add(offset);
        let value = *packed.add(offset + 1);
        if weight < 1 || weight > MAX_WEIGHT || value < 0 || value > MAX_VALUE { return -1; }
    }
    solve(packed, item_count, capacity)
}
