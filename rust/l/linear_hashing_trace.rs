fn bucket_index(key: i64, level: usize, split: usize) -> usize {
    let base = 1_usize << level;
    let index = key.rem_euclid(base as i64) as usize;
    if index < split {
        key.rem_euclid((base << 1) as i64) as usize
    } else {
        index
    }
}

#[no_mangle]
pub extern "C" fn linear_hashing_trace(values: *const i64, length: usize) -> i64 {
    const MAX_OPERATIONS: usize = 63;
    const MAX_BUCKETS: usize = 32;
    if values.is_null() || !(1..=128).contains(&length) {
        return -1;
    }
    // The caller provides the declared i64-array frame at this C ABI boundary.
    let values = unsafe { std::slice::from_raw_parts(values, length) };
    let operation_count = values[0];
    if !(0..=MAX_OPERATIONS as i64).contains(&operation_count)
        || length != 1 + 2 * operation_count as usize
    {
        return -1;
    }

    let mut heads = [-1_i32; MAX_BUCKETS];
    let mut keys = [0_i64; MAX_OPERATIONS];
    let mut links = [-1_i32; MAX_OPERATIONS];
    let mut level = 1_usize;
    let mut split = 0_usize;
    let mut live_count = 0_usize;
    let mut allocated = 0_usize;
    let mut result = 0_i64;

    for operation in 0..operation_count as usize {
        let opcode = values[1 + 2 * operation];
        let key = values[2 + 2 * operation];
        if !(0..=2).contains(&opcode) || !(-1024..=1023).contains(&key) {
            return -1;
        }
        let bucket = bucket_index(key, level, split);
        let mut previous = -1_i32;
        let mut node = heads[bucket];
        while node != -1 && keys[node as usize] != key {
            previous = node;
            node = links[node as usize];
        }
        let found = node != -1;
        let mut succeeded = 0_i64;

        if opcode == 0 && !found {
            node = allocated as i32;
            allocated += 1;
            keys[node as usize] = key;
            links[node as usize] = heads[bucket];
            heads[bucket] = node;
            live_count += 1;
            succeeded = 1;
            let base = 1_usize << level;
            let bucket_count = base + split;
            if bucket_count < MAX_BUCKETS && live_count > 2 * bucket_count {
                let old_bucket = split;
                let new_bucket = base + split;
                let mut current = heads[old_bucket];
                heads[old_bucket] = -1;
                while current != -1 {
                    let following = links[current as usize];
                    let destination = keys[current as usize].rem_euclid((base << 1) as i64) as usize;
                    if destination == new_bucket {
                        links[current as usize] = heads[new_bucket];
                        heads[new_bucket] = current;
                    } else {
                        links[current as usize] = heads[old_bucket];
                        heads[old_bucket] = current;
                    }
                    current = following;
                }
                split += 1;
                if split == base {
                    level += 1;
                    split = 0;
                }
            }
        } else if opcode == 1 && found {
            if previous == -1 {
                heads[bucket] = links[node as usize];
            } else {
                links[previous as usize] = links[node as usize];
            }
            live_count -= 1;
            succeeded = 1;
        } else if opcode == 2 && found {
            succeeded = 1;
        }
        result = (result << 1) | succeeded;
    }
    result
}
