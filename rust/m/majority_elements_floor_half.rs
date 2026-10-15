const MAX_INPUT_LENGTH: usize = 256;
const TABLE_SIZE: usize = 512;

#[no_mangle]
pub unsafe extern "C" fn majority_elements_floor_half(input: *const i64, length: usize,
                                                       output: *mut u8, capacity: usize) -> i64 {
    if length > MAX_INPUT_LENGTH || (length > 0 && input.is_null()) { return -1; }
    let values = if length == 0 { &[] } else { std::slice::from_raw_parts(input, length) };
    let mut keys = [0i32; TABLE_SIZE];
    let mut counts = [0usize; TABLE_SIZE];
    let mut used = [false; TABLE_SIZE];
    let mut order = [0usize; MAX_INPUT_LENGTH];
    let mut unique_count = 0usize;
    for &value in values {
        if value < i32::MIN as i64 || value > i32::MAX as i64 { return -1; }
        let mut remainder = value % TABLE_SIZE as i64;
        if remainder < 0 { remainder += TABLE_SIZE as i64; }
        let mut slot = remainder as usize;
        while used[slot] && keys[slot] as i64 != value { slot = (slot + 1) & (TABLE_SIZE - 1); }
        if !used[slot] { used[slot] = true; keys[slot] = value as i32; counts[slot] = 1; order[unique_count] = slot; unique_count += 1; }
        else { counts[slot] += 1; }
    }
    let threshold = length / 2;
    let mut result = [0i32; MAX_INPUT_LENGTH];
    let mut result_count = 0usize;
    for &slot in &order[..unique_count] {
        if counts[slot] >= threshold { result[result_count] = keys[slot]; result_count += 1; }
    }
    result[..result_count].sort_unstable();
    let required = result_count * 4;
    if capacity < required || (required > 0 && output.is_null()) { return -2; }
    let output = if required == 0 { &mut [] } else { std::slice::from_raw_parts_mut(output, capacity) };
    let mut out = 0usize;
    for &value in &result[..result_count] {
        for byte in value.to_le_bytes() { output[out] = byte; out += 1; }
    }
    result_count as i64
}
