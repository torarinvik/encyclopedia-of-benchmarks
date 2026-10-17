const MAX_N: usize = 64;
const MAX_TIME: i64 = 1_000_000;

#[no_mangle]
pub unsafe extern "C" fn slack_time_scheduling(input: *const i64, length: usize,
    output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 1 || length > 1 + 2 * MAX_N { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    if values[0] < 0 || values[0] > MAX_N as i64 { return -1; }
    let n = values[0] as usize;
    if length != 1 + 2 * n { return -1; }
    let mut slack = [0i64; MAX_N];
    let mut order = [0usize; MAX_N];
    for i in 0..n {
        let execution = values[1 + 2 * i];
        let deadline = values[2 + 2 * i];
        if execution < 0 || execution > MAX_TIME || deadline < 0 || deadline > MAX_TIME { return -1; }
        slack[i] = deadline - execution;
        order[i] = i;
    }
    let bytes = 8 * n;
    if output.is_null() || capacity < bytes { return -2; }
    for i in 1..n {
        let key = order[i];
        let mut j = i;
        while j > 0 && slack[key] < slack[order[j - 1]] { order[j] = order[j - 1]; j -= 1; }
        order[j] = key;
    }
    for i in 0..n { std::ptr::copy_nonoverlapping((order[i] as i64).to_le_bytes().as_ptr(), output.add(i * 8), 8); }
    bytes as i64
}
