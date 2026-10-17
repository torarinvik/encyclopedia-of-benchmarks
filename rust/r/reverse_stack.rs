const MAX_ELEMENTS: usize = 16;

fn insert_at_bottom(items: &mut [i64; MAX_ELEMENTS], size: usize, value: i64) {
    if size == 0 { items[0] = value; return; }
    let top = items[size - 1];
    insert_at_bottom(items, size - 1, value);
    items[size] = top;
}

fn reverse_recursive(items: &mut [i64; MAX_ELEMENTS], size: usize) {
    if size == 0 { return; }
    let top = items[size - 1];
    reverse_recursive(items, size - 1);
    insert_at_bottom(items, size - 1, top);
}

fn put_i64_le(output: &mut [u8], offset: usize, value: i64) {
    output[offset..offset + 8].copy_from_slice(&value.to_le_bytes());
}

#[no_mangle]
pub unsafe extern "C" fn reverse_stack(input: *const i64, length: usize, output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 1 { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let raw_count = values[0];
    if !(0..=MAX_ELEMENTS as i64).contains(&raw_count) || length != raw_count as usize + 1 { return -1; }
    let count = raw_count as usize;
    if values[1..].iter().any(|&value| !(-1_000_000..=1_000_000).contains(&value)) { return -1; }
    let bytes = (count + 1) * 8;
    if output.is_null() || capacity < bytes { return -2; }
    let mut items = [0i64; MAX_ELEMENTS];
    items[..count].copy_from_slice(&values[1..]);
    reverse_recursive(&mut items, count);
    let result = std::slice::from_raw_parts_mut(output, bytes);
    put_i64_le(result, 0, raw_count);
    for i in 0..count { put_i64_le(result, 8 * (i + 1), items[i]); }
    bytes as i64
}
