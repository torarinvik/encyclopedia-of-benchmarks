const MAX_POINTS: usize = 256;

fn spread_16(mut value: u32) -> u32 {
    value = (value | (value << 8)) & 0x00ff_00ff;
    value = (value | (value << 4)) & 0x0f0f_0f0f;
    value = (value | (value << 2)) & 0x3333_3333;
    (value | (value << 1)) & 0x5555_5555
}

fn store_i64_le(output: &mut [u8], offset: usize, value: i64) {
    output[offset..offset + 8].copy_from_slice(&value.to_le_bytes());
}

#[no_mangle]
pub unsafe extern "C" fn morton_sort(input: *const i64, length: usize,
                                      output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || !(3..=513).contains(&length) { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    if values[0] < 1 || values[0] > MAX_POINTS as i64 { return -1; }
    let count = values[0] as usize;
    if length != 1 + 2 * count { return -1; }
    let mut keys = [0u32; MAX_POINTS];
    let mut order = [0usize; MAX_POINTS];
    for index in 0..count {
        let (x, y) = (values[1 + 2 * index], values[2 + 2 * index]);
        if !(0..=65535).contains(&x) || !(0..=65535).contains(&y) { return -1; }
        keys[index] = spread_16(x as u32) | (spread_16(y as u32) << 1);
        order[index] = index;
    }
    let bytes = count * 8;
    if output.is_null() || capacity < bytes { return -2; }
    for index in 1..count {
        let current = order[index];
        let mut position = index;
        while position > 0 &&
              (keys[order[position - 1]] > keys[current] ||
               (keys[order[position - 1]] == keys[current] && order[position - 1] > current)) {
            order[position] = order[position - 1];
            position -= 1;
        }
        order[position] = current;
    }
    let result = std::slice::from_raw_parts_mut(output, capacity);
    for index in 0..count { store_i64_le(result, index * 8, order[index] as i64); }
    bytes as i64
}
