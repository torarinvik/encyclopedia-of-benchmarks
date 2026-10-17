const MAX_OPERATIONS: usize = 128;
const MAX_ENTRIES: usize = 128;
const MAX_INITIAL_CAPACITY: usize = 64;
const MAX_CAPACITY: usize = 256;
const MAX_INPUT_LENGTH: usize = 2 + 3 * MAX_OPERATIONS;
const FNV_OFFSET: u64 = 0xcbf29ce484222325;
const FNV_PRIME: u64 = 0x100000001b3;

fn hash_byte(hash: u64, byte: u8) -> u64 {
    (hash ^ u64::from(byte)).wrapping_mul(FNV_PRIME)
}

fn hash_key(key: i64) -> u64 {
    let mut hash = FNV_OFFSET;
    let mut magnitude = key.unsigned_abs();
    let mut digits = [0_u8; 10];
    let mut count = 0;
    loop {
        digits[count] = (magnitude % 10) as u8;
        count += 1;
        magnitude /= 10;
        if magnitude == 0 { break; }
    }
    if key < 0 { hash = hash_byte(hash, b'-'); }
    while count > 0 {
        count -= 1;
        hash = hash_byte(hash, b'0' + digits[count]);
    }
    hash ^ (hash >> 16)
}

fn bucket_for(key: i64, capacity: usize) -> usize {
    (hash_key(key) & (capacity as u64 - 1)) as usize
}

fn put_i64_le(output: *mut u8, word: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 {
        unsafe { *output.add(word * 8 + byte) = (bits >> (byte * 8)) as u8; }
    }
}

#[no_mangle]
pub unsafe extern "C" fn hashmap(
    input: *const i64,
    length: usize,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT_LENGTH { return -1; }
    let input = unsafe { std::slice::from_raw_parts(input, length) };
    let initial_capacity = input[0];
    let operation_count = input[1];
    if initial_capacity < 1 || initial_capacity as usize > MAX_INITIAL_CAPACITY ||
        (initial_capacity & (initial_capacity - 1)) != 0 || operation_count < 0 ||
        operation_count as usize > MAX_OPERATIONS ||
        length != 2 + 3 * operation_count as usize { return -1; }
    for operation in 0..operation_count as usize {
        let op = input[2 + 3 * operation];
        let key = input[3 + 3 * operation];
        let value = input[4 + 3 * operation];
        if !(0..=2).contains(&op) || key < i32::MIN as i64 || key > i32::MAX as i64 { return -1; }
        if op == 0 {
            if value < i32::MIN as i64 || value > i32::MAX as i64 { return -1; }
        } else if value != 0 { return -1; }
    }

    let mut keys = [0_i64; MAX_ENTRIES];
    let mut values = [0_i64; MAX_ENTRIES];
    let mut results = [0_i64; 1 + 3 * MAX_OPERATIONS + 2];
    let mut next = [-1_i32; MAX_ENTRIES];
    let mut heads = [-1_i32; MAX_CAPACITY];
    let mut tails = [-1_i32; MAX_CAPACITY];
    let mut size = 0_usize;
    let mut map_capacity = initial_capacity as usize;
    let mut result_words = 1_usize;
    let mut query_count = 0_usize;

    for operation in 0..operation_count as usize {
        let op = input[2 + 3 * operation];
        let key = input[3 + 3 * operation];
        let value = input[4 + 3 * operation];
        let bucket = bucket_for(key, map_capacity);
        let mut entry = heads[bucket];
        while entry >= 0 && keys[entry as usize] != key { entry = next[entry as usize]; }
        if op == 0 {
            if entry >= 0 {
                values[entry as usize] = value;
                continue;
            }
            if size >= MAX_ENTRIES { return -1; }
            let node = size;
            size += 1;
            keys[node] = key;
            values[node] = value;
            if heads[bucket] < 0 { heads[bucket] = node as i32; }
            else { next[tails[bucket] as usize] = node as i32; }
            tails[bucket] = node as i32;
            if size * 4 > map_capacity * 3 {
                let mut order = [0_i32; MAX_ENTRIES];
                let mut order_count = 0_usize;
                for old_bucket in 0..map_capacity {
                    let mut node = heads[old_bucket];
                    while node >= 0 {
                        order[order_count] = node;
                        order_count += 1;
                        node = next[node as usize];
                    }
                }
                map_capacity *= 2;
                heads.fill(-1);
                tails.fill(-1);
                next[..size].fill(-1);
                for &node in &order[..order_count] {
                    let node_index = node as usize;
                    let new_bucket = bucket_for(keys[node_index], map_capacity);
                    if heads[new_bucket] < 0 { heads[new_bucket] = node; }
                    else { next[tails[new_bucket] as usize] = node; }
                    tails[new_bucket] = node;
                }
            }
        } else {
            results[result_words] = op;
            result_words += 1;
            if op == 1 {
                results[result_words] = if entry >= 0 { 1 } else { 0 };
                result_words += 1;
                results[result_words] = if entry >= 0 { values[entry as usize] } else { 0 };
                result_words += 1;
            } else {
                results[result_words] = if entry >= 0 { 1 } else { 0 };
                result_words += 1;
            }
            query_count += 1;
        }
    }
    results[0] = query_count as i64;
    results[result_words] = size as i64;
    result_words += 1;
    results[result_words] = map_capacity as i64;
    result_words += 1;
    let output_bytes = result_words * 8;
    if output.is_null() || output_capacity < output_bytes { return -2; }
    for word in 0..result_words { put_i64_le(output, word, results[word]); }
    output_bytes as i64
}
