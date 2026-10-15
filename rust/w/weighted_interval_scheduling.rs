const MAX_INTERVALS: usize = 64;
const MAX_INPUT_LENGTH: usize = 1 + 3 * MAX_INTERVALS;

fn start_at(input: &[i64], index: usize) -> i64 { input[1 + index * 3] }
fn end_at(input: &[i64], index: usize) -> i64 { input[2 + index * 3] }
fn weight_at(input: &[i64], index: usize) -> i64 { input[3 + index * 3] }

fn put_i64_le(output: &mut [u8], offset: usize, value: i64) {
    output[offset..offset + 8].copy_from_slice(&value.to_le_bytes());
}
fn put_i32_le(output: &mut [u8], offset: usize, value: i32) {
    output[offset..offset + 4].copy_from_slice(&value.to_le_bytes());
}

#[no_mangle]
pub unsafe extern "C" fn weighted_interval_scheduling(input: *const i64, length: usize,
                                                         output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 1 || length > MAX_INPUT_LENGTH { return -1; }
    let packed = std::slice::from_raw_parts(input, length);
    if packed[0] < 0 || packed[0] > MAX_INTERVALS as i64 { return -1; }
    let n = packed[0] as usize;
    if length != 1 + 3 * n { return -1; }
    for i in 0..n {
        let start = start_at(packed, i);
        let end = end_at(packed, i);
        let weight = weight_at(packed, i);
        if !(-100_000..=100_000).contains(&start) || !(-100_000..=100_000).contains(&end)
            || start >= end || !(0..=1_000_000).contains(&weight) { return -1; }
    }
    let mut order = [0usize; MAX_INTERVALS];
    let mut predecessors = [0usize; MAX_INTERVALS];
    let mut selected = [0usize; MAX_INTERVALS];
    let mut dp = [0i64; MAX_INTERVALS + 1];
    for i in 0..n { order[i] = i; }
    for i in 1..n {
        let key = order[i];
        let mut j = i;
        while j > 0 && end_at(packed, order[j - 1]) > end_at(packed, key) {
            order[j] = order[j - 1];
            j -= 1;
        }
        order[j] = key;
    }
    for j in 0..n {
        let (mut low, mut high) = (0usize, n);
        while low < high {
            let mid = low + (high - low) / 2;
            if end_at(packed, order[mid]) <= start_at(packed, order[j]) { low = mid + 1; }
            else { high = mid; }
        }
        predecessors[j] = low;
        let include = weight_at(packed, order[j]) + dp[low];
        dp[j + 1] = if include > dp[j] { include } else { dp[j] };
    }
    let (mut selected_count, mut current) = (0usize, n);
    while current > 0 {
        let j = current - 1;
        let include = weight_at(packed, order[j]) + dp[predecessors[j]];
        if include > dp[current - 1] {
            selected[selected_count] = order[j];
            selected_count += 1;
            current = predecessors[j];
        } else { current -= 1; }
    }
    selected[..selected_count].reverse();
    let needed = 16 + 4 * selected_count;
    if output.is_null() || capacity < needed { return -2; }
    let out = std::slice::from_raw_parts_mut(output, needed);
    put_i64_le(out, 0, dp[n]);
    put_i64_le(out, 8, selected_count as i64);
    for i in 0..selected_count { put_i32_le(out, 16 + 4 * i, selected[i] as i32); }
    needed as i64
}
