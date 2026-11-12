const MAX_ROWS: usize = 8;
const HASH_CAPACITY: usize = 17;
const MAX_INPUT: usize = 19;
const MAX_OUTPUT: usize = 64;

fn bucket_for(key: i64) -> usize {
    let mut remainder = key % HASH_CAPACITY as i64;
    if remainder < 0 { remainder += HASH_CAPACITY as i64; }
    remainder as usize
}

#[no_mangle]
pub unsafe extern "C" fn hash_join(input: *const i64, length: usize,
        output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    if values[0] < 0 || values[0] > MAX_ROWS as i64
        || values[1] < 0 || values[1] > MAX_ROWS as i64 { return -1; }
    let left_count = values[0] as usize;
    let right_count = values[1] as usize;
    if length != 2 + left_count + right_count { return -1; }

    let build_left = left_count < right_count;
    let build_count = if build_left { left_count } else { right_count };
    let probe_count = if build_left { right_count } else { left_count };
    let build_offset = if build_left { 2 } else { 2 + left_count };
    let probe_offset = if build_left { 2 + left_count } else { 2 };
    let mut keys = [0_i64; HASH_CAPACITY];
    let mut occupied = [false; HASH_CAPACITY];
    let mut heads = [-1_i32; HASH_CAPACITY];
    let mut tails = [-1_i32; HASH_CAPACITY];
    let mut next_row = [-1_i32; MAX_ROWS];
    let mut staged = [0_u8; MAX_OUTPUT];

    for row in 0..build_count {
        let key = values[build_offset + row];
        let mut slot = bucket_for(key);
        while occupied[slot] && keys[slot] != key { slot = (slot + 1) % HASH_CAPACITY; }
        if !occupied[slot] { occupied[slot] = true; keys[slot] = key; }
        if tails[slot] < 0 { heads[slot] = row as i32; }
        else { next_row[tails[slot] as usize] = row as i32; }
        tails[slot] = row as i32;
    }

    let mut match_count = 0;
    for probe_row in 0..probe_count {
        let key = values[probe_offset + probe_row];
        let mut slot = bucket_for(key);
        while occupied[slot] && keys[slot] != key { slot = (slot + 1) % HASH_CAPACITY; }
        if !occupied[slot] { continue; }
        let mut build_row = heads[slot];
        while build_row >= 0 {
            let build_id = build_row as usize;
            let (left_id, right_id) = if build_left { (build_id, probe_row) } else { (probe_row, build_id) };
            staged[match_count] = ((left_id << 4) | right_id) as u8;
            match_count += 1;
            build_row = next_row[build_id];
        }
    }
    if output.is_null() || capacity < match_count { return -2; }
    std::ptr::copy_nonoverlapping(staged.as_ptr(), output, match_count);
    match_count as i64
}
