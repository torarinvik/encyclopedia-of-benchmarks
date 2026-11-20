/// Return A(n,k), the number of permutations with exactly k descents.
#[no_mangle]
pub unsafe extern "C" fn eulerian_number(values: *const i64, length: usize) -> i64 {
    if values.is_null() || length != 2 { return -1; }
    let values = std::slice::from_raw_parts(values, length);
    let (n, target) = (values[0], values[1]);
    if n < 0 || n > 20 || target < 0
        || (n == 0 && target != 0) || (n > 0 && target >= n) { return -1; }

    let mut previous = [0_i64; 21];
    let mut current = [0_i64; 21];
    previous[0] = 1;
    for row in 1..=n as usize {
        for k in 0..row {
            let same = previous[k];
            let fewer = if k == 0 { 0 } else { previous[k - 1] };
            current[k] = (k as i64 + 1) * same + (row as i64 - k as i64) * fewer;
        }
        for index in 0..21 {
            previous[index] = current[index];
            current[index] = 0;
        }
    }
    previous[target as usize]
}
