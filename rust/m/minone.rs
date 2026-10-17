const MAX_LENGTH: usize = 64;
const MIN_VALUE: i64 = -1_000_000;
const MAX_VALUE: i64 = 1_000_000;

#[no_mangle]
pub unsafe extern "C" fn minone(input: *const i64, length: usize) -> i64 {
    if input.is_null() || !(1..=MAX_LENGTH).contains(&length) { return -1; }
    let mut total = 0_i64;
    for index in 0..length {
        let value = *input.add(index);
        if value < MIN_VALUE || value > MAX_VALUE { return -1; }
        total += value * value;
    }
    total
}
