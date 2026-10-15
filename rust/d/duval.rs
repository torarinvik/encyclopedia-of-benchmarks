/// Least cyclic shift index using Duval's linear-time scan.
#[no_mangle]
pub extern "C" fn duval(values: *const i64, length: usize) -> i64 {
    if length > 4096 { return -1; }
    if length == 0 { return 0; }
    if values.is_null() { return -1; }
    let values = unsafe { std::slice::from_raw_parts(values, length) };
    if values.iter().any(|&value| !(0..=127).contains(&value)) { return -1; }

    let mut i = 0_usize;
    let mut answer = 0_usize;
    while i < length {
        answer = i;
        let mut j = i + 1;
        let mut k = i;
        while j < 2 * length && values[j % length] >= values[k % length] {
            if values[k % length] < values[j % length] { k = i; }
            else { k += 1; }
            j += 1;
        }
        while i <= k { i += j - k; }
    }
    answer as i64
}
