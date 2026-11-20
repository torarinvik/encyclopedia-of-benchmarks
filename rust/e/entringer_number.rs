/// Return one entry of the Entringer triangle using its row recurrence.
#[no_mangle]
pub unsafe extern "C" fn entringer_number(values: *const i64, length: usize) -> i64 {
    if values.is_null() || length != 2 { return -1; }
    let values = std::slice::from_raw_parts(values, length);
    let (n, target) = (values[0], values[1]);
    if n < 0 || n > 12 || target < 0 || target > n { return -1; }
    let mut previous = [0i64; 13];
    let mut current = [0i64; 13];
    previous[0] = 1;
    for row in 1..=n as usize {
        current[0] = 0;
        for col in 1..=row {
            current[col] = current[col - 1] + previous[row - col];
        }
        previous = current;
        current = [0i64; 13];
    }
    previous[target as usize]
}
