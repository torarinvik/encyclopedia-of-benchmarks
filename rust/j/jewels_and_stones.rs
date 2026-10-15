/// Count stones whose ASCII byte appears in the unique-jewel set.
const MAX_JEWELS_LENGTH: usize = 127;
const MAX_STONES_LENGTH: usize = 4096;
const MAX_PACKED_LENGTH: usize = 4225;

#[no_mangle]
pub extern "C" fn jewels_and_stones(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 2 || length > MAX_PACKED_LENGTH { return -1; }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    if values[0] < 0 || values[0] > MAX_JEWELS_LENGTH as i64 ||
        values[1] < 0 || values[1] > MAX_STONES_LENGTH as i64 { return -1; }
    let jewel_count = values[0] as usize;
    let stone_count = values[1] as usize;
    if length != 2 + jewel_count + stone_count { return -1; }
    let mut counts = [0_i64; 128];
    for &value in &values[2..2 + jewel_count] {
        if !(1..=127).contains(&value) || counts[value as usize] != 0 { return -1; }
        counts[value as usize] = 1;
    }
    let mut total = 0_i64;
    for &value in &values[2 + jewel_count..] {
        if !(1..=127).contains(&value) { return -1; }
        total += counts[value as usize];
    }
    total
}
