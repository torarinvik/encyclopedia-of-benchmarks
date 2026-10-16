const MAX_LENGTH: usize = 64;

#[no_mangle]
pub unsafe extern "C" fn jort_sort(values: *const i64, length: usize) -> i64 {
    if length == 0 { return 1; }
    if values.is_null() || length > MAX_LENGTH { return -1; }
    let input = std::slice::from_raw_parts(values, length);
    let mut copy = [0_i64; MAX_LENGTH];
    copy[..length].copy_from_slice(input);
    for i in 2..length {
        let key = copy[i];
        let mut position = i;
        while position > 1 && copy[position - 1] > key {
            copy[position] = copy[position - 1];
            position -= 1;
        }
        copy[position] = key;
    }
    if copy[..length] == input[..] { 1 } else { 0 }
}
