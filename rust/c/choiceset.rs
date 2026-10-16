const MAX_OPERATIONS: usize = 1024;
const MAX_ELEMENTS: usize = 256;
const HASH_CAPACITY: usize = 512;
const MAX_KEY: i64 = 1_000_000_000;

fn hash_slot(value: i32) -> usize {
    let mixed = (value as u32 as u64) * 2_654_435_761u64;
    ((mixed as u32) >> 23) as usize
}

fn find_slot(keys: &[i32; HASH_CAPACITY], states: &[u8; HASH_CAPACITY], value: i32) -> (usize, bool) {
    let mut slot = hash_slot(value);
    let mut deleted = HASH_CAPACITY;
    for _ in 0..HASH_CAPACITY {
        if states[slot] == 0 {
            return (if deleted < HASH_CAPACITY { deleted } else { slot }, false);
        }
        if states[slot] == 2 {
            if deleted == HASH_CAPACITY { deleted = slot; }
        } else if keys[slot] == value {
            return (slot, true);
        }
        slot = (slot + 1) % HASH_CAPACITY;
    }
    (deleted, false)
}

#[no_mangle]
pub unsafe extern "C" fn choiceset(
    values: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if values.is_null() || length < 1 { return -1; }
    let input = std::slice::from_raw_parts(values, length);
    if !(0..=MAX_OPERATIONS as i64).contains(&input[0]) { return -1; }
    let operation_count = input[0] as usize;
    if length != 1 + 2 * operation_count { return -1; }
    let output_bytes = operation_count * 8;

    let mut elements = [0i32; MAX_ELEMENTS];
    let mut map_keys = [0i32; HASH_CAPACITY];
    let mut map_indices = [0usize; HASH_CAPACITY];
    let mut states = [0u8; HASH_CAPACITY];
    let mut results = [0i64; MAX_OPERATIONS];
    let mut element_count = 0usize;

    for operation_index in 0..operation_count {
        let operation = input[1 + 2 * operation_index];
        let argument = input[2 + 2 * operation_index];
        if (1..=3).contains(&operation) {
            if !(-MAX_KEY..=MAX_KEY).contains(&argument) { return -1; }
            let key = argument as i32;
            let (slot, found) = find_slot(&map_keys, &states, key);
            if operation == 1 {
                if found { results[operation_index] = 0; }
                else {
                    if element_count == MAX_ELEMENTS || slot >= HASH_CAPACITY { return -1; }
                    elements[element_count] = key;
                    map_keys[slot] = key;
                    map_indices[slot] = element_count;
                    states[slot] = 1;
                    element_count += 1;
                    results[operation_index] = 1;
                }
            } else if operation == 2 {
                results[operation_index] = i64::from(found);
            } else if !found {
                results[operation_index] = 0;
            } else {
                let index = map_indices[slot];
                let last = element_count - 1;
                if index != last {
                    let moved = elements[last];
                    let (moved_slot, moved_found) = find_slot(&map_keys, &states, moved);
                    if !moved_found { return -1; }
                    elements[index] = moved;
                    map_indices[moved_slot] = index;
                }
                element_count -= 1;
                states[slot] = 2;
                results[operation_index] = 1;
            }
        } else if operation == 4 {
            if argument < 1 || argument as u64 > element_count as u64 { return -1; }
            results[operation_index] = elements[argument as usize - 1] as i64;
        } else { return -1; }
    }
    if capacity < output_bytes || (output_bytes > 0 && output.is_null()) { return -2; }
    for index in 0..operation_count {
        let bits = results[index] as u64;
        for byte in 0..8 { *output.add(index * 8 + byte) = (bits >> (byte * 8)) as u8; }
    }
    output_bytes as i64
}
