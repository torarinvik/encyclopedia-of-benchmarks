/// One-pass two-sum with portable open addressing and first-pair ordering.
#[no_mangle]
pub extern "C" fn two_sum(values: *const i64, length: usize) -> i64 {
    const MAX_VALUES: usize = 256;
    const TABLE_SIZE: usize = 512;
    if values.is_null() || length == 0 || length > MAX_VALUES + 1 {
        return -2;
    }
    let values = unsafe { std::slice::from_raw_parts(values, length) };
    if values.iter().any(|value| *value < i32::MIN as i64 || *value > i32::MAX as i64) {
        return -2;
    }
    let target = values[0];
    let value_count = length - 1;
    let mut capacity = 1usize;
    while capacity < value_count * 2 {
        capacity *= 2;
    }
    let mut keys = [0i64; TABLE_SIZE];
    let mut first_indices = [0usize; TABLE_SIZE];
    let mut occupied = [false; TABLE_SIZE];

    for index in 0..value_count {
        let current = values[index + 1];
        let complement = target - current;
        let mut slot = hash_slot(complement, capacity);
        while occupied[slot] && keys[slot] != complement {
            slot = (slot + 1) % capacity;
        }
        if occupied[slot] {
            return (first_indices[slot] * 256 + index) as i64;
        }
        slot = hash_slot(current, capacity);
        while occupied[slot] && keys[slot] != current {
            slot = (slot + 1) % capacity;
        }
        if !occupied[slot] {
            occupied[slot] = true;
            keys[slot] = current;
            first_indices[slot] = index;
        }
    }
    -1
}

fn hash_slot(key: i64, capacity: usize) -> usize {
    const PRIME: i64 = 2_147_483_647;
    let normalized = (key % PRIME + PRIME) % PRIME;
    let mixed = (normalized * 48_271) % PRIME;
    mixed as usize % capacity
}
