const MAX_ARRAY_LENGTH: usize = 256;
const MAX_INPUT_LENGTH: usize = MAX_ARRAY_LENGTH + 1;
const INT32_MIN: i64 = -2_147_483_648;
const INT32_MAX: i64 = 2_147_483_647;

#[no_mangle]
pub unsafe extern "C" fn how_many_times_rotated(input: *const i64, length: usize) -> i64 {
    if length > MAX_INPUT_LENGTH { return -1; }
    if length > MAX_ARRAY_LENGTH { return -1; }
    if length == 0 { return 0; }
    if input.is_null() { return -1; }
    for index in 0..length {
        let value = *input.add(index);
        if !(INT32_MIN..=INT32_MAX).contains(&value) { return -1; }
    }

    let mut low = 0;
    let mut high = length.saturating_sub(1);
    while low < high {
        let middle = low + (high - low) / 2;
        if *input.add(middle) > *input.add(high) { low = middle + 1; }
        else { high = middle; }
    }
    low as i64
}
