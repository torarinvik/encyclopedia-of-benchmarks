#[no_mangle]
pub extern "C" fn shortest_subarray_with_sum_at_least_k(
    packed: *const i64,
    length: usize,
) -> i64 {
    if packed.is_null() || length < 2 || length > 259 {
        return -1;
    }
    let input = unsafe { std::slice::from_raw_parts(packed, length) };
    let target = input[0];
    let count = input[1];
    if !(-4096..=4096).contains(&target)
        || !(0..=256).contains(&count)
        || length != count as usize + 2
    {
        return -1;
    }
    let n = count as usize;
    let mut prefix = [0i64; 257];
    for index in 0..n {
        let value = input[index + 2];
        if !(-1000..=1000).contains(&value) {
            return -1;
        }
        prefix[index + 1] = prefix[index] + value;
    }

    let mut deque = [0usize; 257];
    let mut head = 0usize;
    let mut tail = 0usize;
    let mut best = n + 1;
    for right in 0..=n {
        while head < tail && prefix[right] - prefix[deque[head]] >= target {
            best = best.min(right - deque[head]);
            head += 1;
        }
        while head < tail && prefix[right] <= prefix[deque[tail - 1]] {
            tail -= 1;
        }
        deque[tail] = right;
        tail += 1;
    }
    if best <= n { best as i64 } else { 0 }
}

