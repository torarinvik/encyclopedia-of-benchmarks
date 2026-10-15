/// Return the absent value from 0 through the number of supplied values.
const MAX_VALUES: usize = 1024;

#[no_mangle]
pub extern "C" fn missing_number(values: *const i64, length: usize) -> i64 {
    if length > MAX_VALUES || (length != 0 && values.is_null()) { return -1; }
    let mut seen = [false; MAX_VALUES + 1];
    let mut actual_sum = 0i64;
    for index in 0..length {
        let value = unsafe { *values.add(index) };
        if value < 0 || value > length as i64 { return -1; }
        let slot = value as usize;
        if seen[slot] { return -1; }
        seen[slot] = true;
        actual_sum += value;
    }
    let n = length as i64;
    n * (n + 1) / 2 - actual_sum
}
