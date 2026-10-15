/// Return the first lowercase ASCII letter whose frequency is one.
const MAX_LENGTH: usize = 1024;

#[no_mangle]
pub extern "C" fn first_unique_character(values: *const i64, length: usize) -> i64 {
    if length > MAX_LENGTH || (length != 0 && values.is_null()) { return -2; }
    let mut counts = [0usize; 26];
    for index in 0..length {
        let value = unsafe { *values.add(index) };
        if !(97..=122).contains(&value) { return -2; }
        counts[(value - 97) as usize] += 1;
    }
    for index in 0..length {
        let slot = (unsafe { *values.add(index) } - 97) as usize;
        if counts[slot] == 1 { return index as i64; }
    }
    -1
}
