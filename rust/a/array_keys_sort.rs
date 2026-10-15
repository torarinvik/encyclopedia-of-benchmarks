fn store_i64_le(output: &mut [u8], offset: usize, value: i64) {
    output[offset..offset + 8].copy_from_slice(&value.to_le_bytes());
}
fn compare_rows(left: &[i64; 4], right: &[i64; 4], keys: &[usize], ascending: bool) -> std::cmp::Ordering {
    for &field in keys {
        match left[field].cmp(&right[field]) {
            std::cmp::Ordering::Equal => {},
            order => return if ascending { order } else { order.reverse() },
        }
    }
    std::cmp::Ordering::Equal
}
#[no_mangle]
pub unsafe extern "C" fn array_keys_sort(values: *const i64, length: usize, output: *mut u8, capacity: usize) -> i64 {
    if values.is_null() || !(8..=263).contains(&length) { return -1; }
    let input = std::slice::from_raw_parts(values, length);
    let raw_count = input[0]; let raw_key_count = input[1]; let order = input[2];
    if !(1..=64).contains(&raw_count) || !(1..=4).contains(&raw_key_count) || (order != 0 && order != 1) { return -1; }
    let count = raw_count as usize; let key_count = raw_key_count as usize;
    if length != 3 + key_count + 4 * count { return -1; }
    let mut keys = [0usize; 4];
    for index in 0..key_count {
        let key = input[3 + index];
        if !(1..=4).contains(&key) { return -1; }
        if keys[..index].contains(&(key as usize)) { return -1; }
        keys[index] = key as usize - 1;
    }
    let mut rows = [[0i64; 4]; 64];
    let rows_start = 3 + key_count;
    for row in 0..count {
        for column in 0..4 {
            let value = input[rows_start + row * 4 + column];
            if !(-1000..=1000).contains(&value) { return -1; }
            rows[row][column] = value;
        }
    }
    for left in 0..count { for right in left + 1..count {
        if compare_rows(&rows[left], &rows[right], &keys[..key_count], true) == std::cmp::Ordering::Equal { return -1; }
    }}
    let byte_count = 32 * count;
    if output.is_null() || capacity < byte_count { return -2; }
    for index in 1..count {
        let temporary = rows[index];
        let mut position = index;
        while position > 0 && compare_rows(&rows[position - 1], &temporary, &keys[..key_count], order == 1) == std::cmp::Ordering::Greater {
            rows[position] = rows[position - 1]; position -= 1;
        }
        rows[position] = temporary;
    }
    let result = std::slice::from_raw_parts_mut(output, capacity);
    for row in 0..count { for column in 0..4 { store_i64_le(result, 8 * (row * 4 + column), rows[row][column]); }}
    byte_count as i64
}
