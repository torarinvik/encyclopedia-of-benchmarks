const SLOTS: usize = 16;
const FEATURES: usize = 3;
const MAX_OPERATIONS: usize = 64;
const BASE_WORDS: usize = 1 + SLOTS * FEATURES + SLOTS;
const MAX_VALID_WORDS: usize = BASE_WORDS + 2 * MAX_OPERATIONS;

fn store_hash(output: *mut u8, offset: usize, value: u64) {
    for byte in 0..8 {
        unsafe { output.add(offset + byte).write((value >> (8 * byte)) as u8); }
    }
}

#[no_mangle]
pub unsafe extern "C" fn zobrist_position_hash_trace(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input.is_null() || length < BASE_WORDS || length > MAX_VALID_WORDS + 1 { return -1; }
    let count_value = *input;
    if count_value < 0 || count_value as usize > MAX_OPERATIONS { return -1; }
    let count = count_value as usize;
    if length != BASE_WORDS + 2 * count { return -1; }

    for index in 0..SLOTS * FEATURES {
        if *input.add(1 + index) < 0 { return -1; }
    }
    let state_start = 1 + SLOTS * FEATURES;
    for slot in 0..SLOTS {
        let feature = *input.add(state_start + slot);
        if !(0..=FEATURES as i64).contains(&feature) { return -1; }
    }
    let edits_start = state_start + SLOTS;
    for edit in 0..count {
        let slot = *input.add(edits_start + 2 * edit);
        let feature = *input.add(edits_start + 2 * edit + 1);
        if slot < 0 || slot as usize >= SLOTS || feature < 0 || feature > FEATURES as i64 {
            return -1;
        }
    }

    let required = 8 * (count + 1);
    if output.is_null() || capacity < required { return -2; }

    let mut board = [0u8; SLOTS];
    let mut hash = 0u64;
    for slot in 0..SLOTS {
        let feature = *input.add(state_start + slot) as u8;
        board[slot] = feature;
        if feature != 0 {
            hash ^= *input.add(1 + slot * FEATURES + feature as usize - 1) as u64;
        }
    }
    store_hash(output, 0, hash);
    for edit in 0..count {
        let slot = *input.add(edits_start + 2 * edit) as usize;
        let next = *input.add(edits_start + 2 * edit + 1) as u8;
        let previous = board[slot];
        if previous != 0 {
            hash ^= *input.add(1 + slot * FEATURES + previous as usize - 1) as u64;
        }
        if next != 0 {
            hash ^= *input.add(1 + slot * FEATURES + next as usize - 1) as u64;
        }
        board[slot] = next;
        store_hash(output, 8 * (edit + 1), hash);
    }
    required as i64
}
