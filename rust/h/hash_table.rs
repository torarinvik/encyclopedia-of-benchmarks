/// Collision-free integer-set membership for the shared hash-table contract.
const TABLE_CAPACITY: usize = 17;
const MAX_INSERT_COUNT: i64 = 8;
const MAX_QUERY_COUNT: i64 = 8;
const MAX_KEY: i64 = 1000;
const MAX_PARSEABLE_LENGTH: usize = 19;

fn store_i64_le(output: *mut u8, offset: usize, value: i64) {
    let bytes = value.to_le_bytes();
    for (index, byte) in bytes.iter().enumerate() {
        unsafe { *output.add(offset + index) = *byte; }
    }
}

#[no_mangle]
pub unsafe extern "C" fn hash_table(
    values: *const i64,
    length: usize,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if values.is_null() || length < 2 || length > MAX_PARSEABLE_LENGTH {
        return -1;
    }
    let raw_insert_count = *values;
    if !(0..=MAX_INSERT_COUNT).contains(&raw_insert_count) {
        return -1;
    }
    let insert_count = raw_insert_count as usize;
    let query_count_index = 1 + insert_count;
    if query_count_index >= length {
        return -1;
    }
    let raw_query_count = *values.add(query_count_index);
    if !(1..=MAX_QUERY_COUNT).contains(&raw_query_count) {
        return -1;
    }
    let query_count = raw_query_count as usize;
    let query_start = query_count_index + 1;
    let total_keys = insert_count + query_count;
    if length != query_start + query_count {
        return -1;
    }

    for index in 0..total_keys {
        let position = if index < insert_count { 1 + index } else { query_start + index - insert_count };
        let key = *values.add(position);
        if !(1..=MAX_KEY).contains(&key) {
            return -1;
        }
        for prior in 0..index {
            let prior_position = if prior < insert_count { 1 + prior } else { query_start + prior - insert_count };
            let other = *values.add(prior_position);
            let same_group = (index < insert_count) == (prior < insert_count);
            if key == other {
                if same_group {
                    return -1;
                }
            } else if key % TABLE_CAPACITY as i64 == other % TABLE_CAPACITY as i64
                || key % 3000 == other % 3000
            {
                return -1;
            }
        }
    }

    let mut table = [0i64; TABLE_CAPACITY];
    for index in 0..insert_count {
        let key = *values.add(1 + index);
        table[(key % TABLE_CAPACITY as i64) as usize] = key;
    }

    let output_bytes = 8 * query_count;
    if output.is_null() || output_capacity < output_bytes {
        return -2;
    }
    for index in 0..query_count {
        let query = *values.add(query_start + index);
        let found = i64::from(table[(query % TABLE_CAPACITY as i64) as usize] == query);
        store_i64_le(output, 8 * index, found);
    }
    output_bytes as i64
}
