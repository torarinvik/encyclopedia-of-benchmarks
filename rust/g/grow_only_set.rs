#[no_mangle]
pub unsafe extern "C" fn grow_only_set(values: *const i64, length: usize) -> i64 {
    if values.is_null() || !(1..=25).contains(&length) { return -1; }
    let values = std::slice::from_raw_parts(values, length);
    let count_value = values[0];
    if !(0..=12).contains(&count_value) || length != 1 + 2 * count_value as usize { return -1; }
    let mut left = 0u64;
    let mut right = 0u64;
    let mut answers = 0u64;
    let mut query_count = 0usize;
    for index in 0..count_value as usize {
        let opcode = values[1 + 2 * index];
        let argument = values[2 + 2 * index];
        if !(0..=7).contains(&opcode) { return -1; }
        if opcode <= 3 {
            if !(0..=15).contains(&argument) { return -1; }
        } else if argument != 0 { return -1; }
        let bit = if opcode <= 3 { 1u64 << argument as u32 } else { 0 };
        match opcode {
            0 => left |= bit,
            1 => right |= bit,
            2 => {
                if left & bit != 0 { answers |= 1u64 << query_count; }
                query_count += 1;
            }
            3 => {
                if right & bit != 0 { answers |= 1u64 << query_count; }
                query_count += 1;
            }
            4 => {
                if left & right == left { answers |= 1u64 << query_count; }
                query_count += 1;
            }
            5 => {
                if left & right == right { answers |= 1u64 << query_count; }
                query_count += 1;
            }
            6 => left |= right,
            _ => right |= left,
        }
    }
    (answers | (left << 12) | (right << 28) | ((query_count as u64) << 44)) as i64
}
