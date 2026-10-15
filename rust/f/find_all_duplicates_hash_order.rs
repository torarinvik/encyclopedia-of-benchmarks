const MAX_INPUT_LENGTH: usize = 1024;
const TABLE_SIZE: usize = 2048;

#[no_mangle]
pub unsafe extern "C" fn find_all_duplicates_hash_order(input: *const i64, length: usize,
                                                         output: *mut u8, capacity: usize) -> i64 {
    if length > MAX_INPUT_LENGTH || (length > 0 && input.is_null()) { return -1; }
    let values = if length == 0 { &[] } else { std::slice::from_raw_parts(input, length) };
    let mut keys = [0i64; TABLE_SIZE];
    let mut counts = [0usize; TABLE_SIZE];
    let mut used = [false; TABLE_SIZE];
    let mut order = [0usize; MAX_INPUT_LENGTH];
    let mut unique_count = 0usize;
    for &value in values {
        let mut remainder = value % TABLE_SIZE as i64;
        if remainder < 0 { remainder += TABLE_SIZE as i64; }
        let mut slot = remainder as usize;
        while used[slot] && keys[slot] != value { slot = (slot + 1) & (TABLE_SIZE - 1); }
        if !used[slot] { used[slot] = true; keys[slot] = value; counts[slot] = 1; order[unique_count] = slot; unique_count += 1; }
        else { counts[slot] += 1; }
    }
    let duplicate_count = order[..unique_count].iter().filter(|&&slot| counts[slot] > 1).count();
    let required = duplicate_count * 8;
    if capacity < required || (required > 0 && output.is_null()) { return -2; }
    let output = if required == 0 { &mut [] } else { std::slice::from_raw_parts_mut(output, capacity) };
    let mut out = 0usize;
    for &slot in &order[..unique_count] {
        if counts[slot] <= 1 { continue; }
        let bits = keys[slot] as u64;
        for byte in 0..8 { output[out] = (bits >> (byte * 8)) as u8; out += 1; }
    }
    duplicate_count as i64
}
