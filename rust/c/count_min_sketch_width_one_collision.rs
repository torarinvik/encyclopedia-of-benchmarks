fn put_i64_le(output: &mut [u8], offset: usize, value: i64) {
    output[offset..offset + 8].copy_from_slice(&value.to_le_bytes());
}

#[no_mangle]
pub unsafe extern "C" fn count_min_sketch_width_one_collision(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || length < 1 || length > 513 { return -1; }
    let values = unsafe { core::slice::from_raw_parts(input, length) };
    let count_value = values[0];
    if !(0..=256).contains(&count_value) { return -1; }
    let count = count_value as usize;
    if length != 1 + count * 2 { return -1; }
    let mut queries = 0usize;
    for i in 0..count {
        let operation = values[1 + 2 * i];
        let key = values[2 + 2 * i];
        if (operation != 0 && operation != 1) || !(-1_000_000..=1_000_000).contains(&key) { return -1; }
        if operation == 1 { queries += 1; }
    }
    let required = queries * 8;
    if capacity < required || (required > 0 && output.is_null()) { return -2; }
    let result = if required == 0 { &mut [][..] } else { unsafe { core::slice::from_raw_parts_mut(output, required) } };
    let mut inserts = 0i64;
    let mut output_offset = 0usize;
    for i in 0..count {
        if values[1 + 2 * i] == 0 { inserts += 1; }
        else { put_i64_le(result, output_offset, inserts); output_offset += 8; }
    }
    required as i64
}
