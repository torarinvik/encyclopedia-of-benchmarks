const MAX_N: usize = 32;
const MAX_INPUT: usize = 35;

unsafe fn store_i64_le(output: *mut u8, offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 { *output.add(offset + byte) = (bits >> (8 * byte)) as u8; }
}

#[no_mangle]
pub unsafe extern "C" fn max_sum_length_bounded_segment(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || length < 4 || length > MAX_INPUT { return -1; }
    let n64 = *input;
    let lower64 = *input.add(1);
    let upper64 = *input.add(2);
    if n64 < 1 || n64 > MAX_N as i64 || lower64 < 1 || upper64 < lower64 || upper64 > n64
        || length != 3 + n64 as usize { return -1; }
    let n = n64 as usize;
    let lower = lower64 as usize;
    let upper = upper64 as usize;
    let mut prefix = [0i64; MAX_N + 1];
    for i in 0..n {
        let value = *input.add(3 + i);
        if !(-10000..=10000).contains(&value) { return -1; }
        prefix[i + 1] = prefix[i] + value;
    }
    if output.is_null() || capacity < 24 { return -2; }
    let mut deque = [0usize; MAX_N + 1];
    let (mut head, mut tail) = (0usize, 0usize);
    let (mut best_sum, mut best_start, mut best_end) = (0i64, 0usize, 0usize);
    let mut have_best = false;
    for end in lower..=n {
        let added = end - lower;
        while tail > head && prefix[deque[tail - 1]] > prefix[added] { tail -= 1; }
        deque[tail] = added;
        tail += 1;
        let earliest = end.saturating_sub(upper);
        while head < tail && deque[head] < earliest { head += 1; }
        let start = deque[head];
        let total = prefix[end] - prefix[start];
        if !have_best || total > best_sum ||
            (total == best_sum && (start < best_start || (start == best_start && end < best_end))) {
            best_sum = total; best_start = start; best_end = end; have_best = true;
        }
    }
    store_i64_le(output, 0, best_sum);
    store_i64_le(output, 8, best_start as i64);
    store_i64_le(output, 16, best_end as i64);
    24
}
