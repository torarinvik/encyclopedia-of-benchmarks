#[no_mangle]
pub unsafe extern "C" fn chaining(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 2 || length > 260 { return -1; }
    let bucket_count_value = *input;
    let operation_count_value = *input.add(1);
    if !(1..=127).contains(&bucket_count_value) || !(0..=128).contains(&operation_count_value) {
        return -1;
    }
    let bucket_count = bucket_count_value as usize;
    let operation_count = operation_count_value as usize;
    if length != 2 + 2 * operation_count { return -1; }

    let mut heads = [-1_i64; 127];
    let mut keys = [0_i64; 128];
    let mut next = [-1_i64; 128];
    let mut inserted = 0_usize;
    let mut query_count = 0_usize;
    let mut result = 0_u64;
    for operation_index in 0..operation_count {
        let operation = *input.add(2 + 2 * operation_index);
        let key = *input.add(3 + 2 * operation_index);
        if (operation != 0 && operation != 1) || !(0..=i32::MAX as i64).contains(&key) {
            return -1;
        }
        let bucket = (key % bucket_count_value) as usize;
        if operation == 0 {
            if inserted >= keys.len() { return -1; }
            keys[inserted] = key;
            if heads[bucket] < 0 { heads[bucket] = inserted as i64; }
            else {
                let mut node = heads[bucket];
                while next[node as usize] >= 0 { node = next[node as usize]; }
                next[node as usize] = inserted as i64;
            }
            inserted += 1;
        } else {
            if query_count >= 63 { return -1; }
            let mut node = heads[bucket];
            while node >= 0 && keys[node as usize] != key { node = next[node as usize]; }
            if node >= 0 { result |= 1_u64 << query_count; }
            query_count += 1;
        }
    }
    result as i64
}
