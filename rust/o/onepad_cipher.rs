const MAX_TEXT_LENGTH: usize = 1024;

fn store_i64_le(value: i64, output: *mut u8) {
    let bits = value as u64;
    for byte in 0..8 {
        unsafe { *output.add(byte) = (bits >> (8 * byte)) as u8; }
    }
}

#[no_mangle]
pub unsafe extern "C" fn onepad_cipher(input: *const i64, length: usize,
                                         output: *mut u8, output_capacity: usize) -> i64 {
    if input.is_null() || length < 2 || length > 2 + 2 * MAX_TEXT_LENGTH { return -1; }
    let mode = *input;
    let count_value = *input.add(1);
    if (mode != 0 && mode != 1) || count_value < 0 || count_value > MAX_TEXT_LENGTH as i64 { return -1; }
    let count = count_value as usize;
    if length != 2 + 2 * count { return -1; }
    let needed = if mode == 0 { 8 * count } else { count };
    if output_capacity < needed || (needed > 0 && output.is_null()) { return -2; }
    for index in 0..count {
        let data = *input.add(2 + index);
        let key = *input.add(2 + count + index);
        if !(1..=300).contains(&key) { return -1; }
        if mode == 0 {
            if !(32..=126).contains(&data) { return -1; }
            store_i64_le((data + key) * key, output.add(8 * index));
        } else {
            let key_square = key * key;
            if data < key_square || (data - key_square) % key != 0 { return -1; }
            let plain = (data - key_square) / key;
            if !(32..=126).contains(&plain) { return -1; }
            *output.add(index) = plain as u8;
        }
    }
    needed as i64
}
