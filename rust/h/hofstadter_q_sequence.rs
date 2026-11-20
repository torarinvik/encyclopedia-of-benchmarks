const MAX_INDEX: i64 = 128;

#[no_mangle]
pub unsafe extern "C" fn hofstadter_q_sequence(input: *const i64, length: usize) -> i64 {
    if input.is_null() || !(1..=2).contains(&length) { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    if length != 1 || !(1..=MAX_INDEX).contains(&values[0]) { return -1; }

    let target = values[0] as usize;
    let mut q = [0_i64; 129];
    q[1] = 1;
    if target >= 2 { q[2] = 1; }
    for n in 3..=target {
        let left = n as i64 - q[n - 1];
        let right = n as i64 - q[n - 2];
        if left < 1 || right < 1 || left >= n as i64 || right >= n as i64 { return -1; }
        q[n] = q[left as usize] + q[right as usize];
    }
    q[target]
}
