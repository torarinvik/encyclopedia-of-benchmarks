/// Return twice the statistical median using a local insertion-sorted copy.
#[no_mangle]
pub extern "C" fn median(values: *const i64, length: usize) -> i64 {
    if length == 0 || length > 1024 { return 0; }
    let input = unsafe { std::slice::from_raw_parts(values, length) };
    let mut ordered = [0i64; 1024];
    ordered[..length].copy_from_slice(input);
    for index in 1..length {
        let value = ordered[index];
        let mut cursor = index;
        while cursor > 0 && ordered[cursor - 1] > value {
            ordered[cursor] = ordered[cursor - 1];
            cursor -= 1;
        }
        ordered[cursor] = value;
    }
    if length % 2 != 0 { return ordered[length / 2] * 2; }
    ordered[length / 2 - 1] + ordered[length / 2]
}
