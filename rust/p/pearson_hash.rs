const TABLE_SIZE: usize = 256;
const MAX_TEXT: usize = 64;
const MAX_WORDS: usize = 1 + TABLE_SIZE + MAX_TEXT;

#[no_mangle]
pub unsafe extern "C" fn pearson_hash(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 1 + TABLE_SIZE || length > MAX_WORDS + 1 {
        return -1;
    }
    let frame = std::slice::from_raw_parts(input, length);
    let declared = frame[0];
    if declared < 0 || declared > MAX_TEXT as i64
        || length != 1 + TABLE_SIZE + declared as usize {
        return -1;
    }

    let mut table = [0u8; TABLE_SIZE];
    let mut used = [false; TABLE_SIZE];
    for slot in 0..TABLE_SIZE {
        let value = frame[1 + slot];
        if !(0..=255).contains(&value) || used[value as usize] {
            return -1;
        }
        table[slot] = value as u8;
        used[value as usize] = true;
    }
    let text_start = 1 + TABLE_SIZE;
    for &byte in &frame[text_start..] {
        if !(0..=255).contains(&byte) { return -1; }
    }

    let mut state = 0u8;
    for &byte in &frame[text_start..] {
        state = table[(state ^ byte as u8) as usize];
    }
    i64::from(state)
}
