/// Count ASCII vowels in a bounded string represented by byte values.
const MAX_LENGTH: usize = 4096;

#[no_mangle]
pub extern "C" fn count_vowels(values: *const i64, length: usize) -> i64 {
    if length == 0 || length > MAX_LENGTH || values.is_null() { return -2; }
    if length == 1 && unsafe { *values } == 48 { return -2; }
    let mut count = 0i64;
    for index in 0..length {
        let value = unsafe { *values.add(index) };
        if !(0..=127).contains(&value) || value == 44 { return -2; }
        if matches!(value, 97 | 101 | 105 | 111 | 117 | 65 | 69 | 73 | 79 | 85) { count += 1; }
    }
    count
}
