const MAX_OPERATIONS: usize = 512;
const MAX_ENTRIES: usize = 128;
const MAX_KEY: i64 = 99_999;
const BUCKET_COUNT: usize = 16;
const MAX_INPUT_LENGTH: usize = 1537;
const FNV_OFFSET: u64 = 0xcbf29ce484222325;
const FNV_PRIME: u64 = 0x100000001b3;
const RESULT_MASK: u64 = 0x7fffffffffffffff;

fn hash_byte(hash: u64, byte: u8) -> u64 {
    (hash ^ byte as u64).wrapping_mul(FNV_PRIME)
}

fn hash_i32(mut hash: u64, value: i64) -> u64 {
    let bits = value as u32;
    for shift in [0, 8, 16, 24] {
        hash = hash_byte(hash, (bits >> shift) as u8);
    }
    hash
}

fn find_entry(keys: &[i64; MAX_ENTRIES], next: &[i32; MAX_ENTRIES],
              buckets: &[i32; BUCKET_COUNT], key: i64) -> i32 {
    let bucket = (key % BUCKET_COUNT as i64) as usize;
    let mut entry = buckets[bucket];
    while entry >= 0 {
        let index = entry as usize;
        if keys[index] == key { return entry; }
        entry = next[index];
    }
    -1
}

#[no_mangle]
pub unsafe extern "C" fn hash_map_separate_chaining(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 1 || length > MAX_INPUT_LENGTH { return -1; }
    let input = unsafe { std::slice::from_raw_parts(input, length) };
    let operation_count = input[0];
    if operation_count < 0 || operation_count as usize > MAX_OPERATIONS ||
        length != 1 + 3 * operation_count as usize { return -1; }

    let mut keys = [0_i64; MAX_ENTRIES];
    let mut mapped_values = [0_i64; MAX_ENTRIES];
    let mut next = [-1_i32; MAX_ENTRIES];
    let mut buckets = [-1_i32; BUCKET_COUNT];
    let mut free_slots = [0_i32; MAX_ENTRIES];
    for index in 0..MAX_ENTRIES { free_slots[index] = index as i32; }
    let mut free_count = MAX_ENTRIES;
    let mut size = 0;
    let mut hash = FNV_OFFSET;

    for operation in 0..operation_count as usize {
        let opcode = input[1 + 3 * operation];
        let key = input[2 + 3 * operation];
        let value = input[3 + 3 * operation];
        let mut result_code = 0_u8;
        let mut returned_value = 0_i64;

        if opcode == 0 {
            if !(0..=MAX_KEY).contains(&key) || value < i32::MIN as i64 || value > i32::MAX as i64 {
                return -1;
            }
            let entry = find_entry(&keys, &next, &buckets, key);
            if entry >= 0 { mapped_values[entry as usize] = value; }
            else {
                if size >= MAX_ENTRIES { return -1; }
                free_count -= 1;
                let slot = free_slots[free_count] as usize;
                keys[slot] = key; mapped_values[slot] = value;
                let bucket = (key % BUCKET_COUNT as i64) as usize;
                next[slot] = buckets[bucket]; buckets[bucket] = slot as i32; size += 1;
            }
        } else if opcode == 1 {
            if !(0..=MAX_KEY).contains(&key) || value != 0 { return -1; }
            let entry = find_entry(&keys, &next, &buckets, key);
            if entry >= 0 { result_code = 1; returned_value = mapped_values[entry as usize]; }
        } else if opcode == 2 {
            if !(0..=MAX_KEY).contains(&key) || value != 0 { return -1; }
            let bucket = (key % BUCKET_COUNT as i64) as usize;
            let mut previous = -1_i32;
            let mut entry = buckets[bucket];
            while entry >= 0 {
                let index = entry as usize;
                let following = next[index];
                if keys[index] == key {
                    if previous < 0 { buckets[bucket] = following; }
                    else { next[previous as usize] = following; }
                    free_slots[free_count] = entry; free_count += 1; size -= 1; break;
                }
                previous = entry; entry = following;
            }
        } else if opcode == 3 {
            if !(0..=MAX_KEY).contains(&key) || value != 0 { return -1; }
            result_code = u8::from(find_entry(&keys, &next, &buckets, key) >= 0);
        } else if opcode == 4 {
            if key != 0 || value != 0 { return -1; }
            buckets.fill(-1); next.fill(-1);
            for index in 0..MAX_ENTRIES { free_slots[index] = index as i32; }
            free_count = MAX_ENTRIES; size = 0;
        } else { return -1; }

        hash = hash_byte(hash, opcode as u8);
        hash = hash_byte(hash, result_code);
        if opcode == 1 && result_code == 1 { hash = hash_i32(hash, returned_value); }
    }
    (hash & RESULT_MASK) as i64
}
