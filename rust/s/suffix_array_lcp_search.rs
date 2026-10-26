const MAX_N: usize = 32;
const MAX_M: usize = 16;
const MAX_INPUT: usize = 50;
const MAX_OUTPUT: usize = 264;

fn suffix_cmp(text: &[i64; MAX_N], a: usize, b: usize, n: usize) -> i32 {
    let mut k = 0;
    while a + k < n && b + k < n {
        if text[a + k] < text[b + k] { return -1; }
        if text[a + k] > text[b + k] { return 1; }
        k += 1;
    }
    if a + k == n && b + k == n { 0 } else if a + k == n { -1 } else { 1 }
}

fn pattern_cmp(text: &[i64; MAX_N], start: usize, n: usize,
    pattern: &[i64; MAX_M], m: usize, offset: usize, prefix_equal: bool) -> (i32, usize) {
    let mut matched = offset;
    while matched < m && start + matched < n && text[start + matched] == pattern[matched] {
        matched += 1;
    }
    if matched == m {
        if prefix_equal || start + matched == n { return (0, matched); }
        return (1, matched);
    }
    if start + matched == n { return (-1, matched); }
    (if text[start + matched] < pattern[matched] { -1 } else { 1 }, matched)
}

fn build_intervals(n: usize, lcp: &[usize; MAX_N],
    left_q: &mut [usize; MAX_N * MAX_N], right_q: &mut [usize; MAX_N * MAX_N]) {
    let mut lo_stack = [0usize; 2 * MAX_N];
    let mut hi_stack = [0usize; 2 * MAX_N];
    let mut top = 1;
    lo_stack[0] = 0;
    hi_stack[0] = n - 1;
    while top > 0 {
        top -= 1;
        let lo = lo_stack[top];
        let hi = hi_stack[top];
        if hi - lo < 2 { continue; }
        let mid = (lo + hi + 1) / 2;
        let mut q = n + 1;
        for k in lo..mid { if lcp[k] < q { q = lcp[k]; } }
        left_q[lo * MAX_N + hi] = q;
        q = n + 1;
        for k in mid..hi { if lcp[k] < q { q = lcp[k]; } }
        right_q[lo * MAX_N + hi] = q;
        if hi - mid >= 2 { lo_stack[top] = mid; hi_stack[top] = hi; top += 1; }
        if mid - lo >= 2 { lo_stack[top] = lo; hi_stack[top] = mid; top += 1; }
    }
}

fn bound(text: &[i64; MAX_N], n: usize, pattern: &[i64; MAX_M], m: usize,
    suffix: &[usize; MAX_N], left_q: &[usize; MAX_N * MAX_N],
    right_q: &[usize; MAX_N * MAX_N], prefix_equal: bool) -> usize {
    let (first, mut l) = pattern_cmp(text, suffix[0], n, pattern, m, 0, prefix_equal);
    if first > 0 || (!prefix_equal && first == 0) { return 0; }
    let (last, mut r) = pattern_cmp(text, suffix[n - 1], n, pattern, m, 0, prefix_equal);
    if last < 0 || (prefix_equal && last == 0) { return n; }
    let (mut lo, mut hi) = (0, n - 1);
    while hi - lo > 1 {
        let mid = (lo + hi + 1) / 2;
        if l == r {
            let (cmp, matched) = pattern_cmp(text, suffix[mid], n, pattern, m, l, prefix_equal);
            if cmp > 0 || (!prefix_equal && cmp == 0) { hi = mid; r = matched; }
            else { lo = mid; l = matched; }
        } else if l > r {
            let q = left_q[lo * MAX_N + hi];
            if l < q { lo = mid; }
            else if l > q { hi = mid; r = q; }
            else {
                let (cmp, matched) = pattern_cmp(text, suffix[mid], n, pattern, m, l, prefix_equal);
                if cmp > 0 || (!prefix_equal && cmp == 0) { hi = mid; r = matched; }
                else { lo = mid; l = matched; }
            }
        } else {
            let q = right_q[lo * MAX_N + hi];
            if r < q { hi = mid; }
            else if r > q { lo = mid; l = q; }
            else {
                let (cmp, matched) = pattern_cmp(text, suffix[mid], n, pattern, m, r, prefix_equal);
                if cmp > 0 || (!prefix_equal && cmp == 0) { hi = mid; r = matched; }
                else { lo = mid; l = matched; }
            }
        }
    }
    hi
}

#[no_mangle]
pub unsafe extern "C" fn suffix_array_lcp_search(
    values: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if values.is_null() || length < 3 || length > MAX_INPUT { return -1; }
    let input = std::slice::from_raw_parts(values, length);
    if input[0] < 1 || input[0] > MAX_N as i64 { return -1; }
    let n = input[0] as usize;
    if length < n + 2 || input[n + 1] < 1 || input[n + 1] > MAX_M as i64 { return -1; }
    let m = input[n + 1] as usize;
    if length != n + m + 2 { return -1; }
    let mut text = [0i64; MAX_N];
    let mut pattern = [0i64; MAX_M];
    let mut suffix = [0usize; MAX_N];
    let mut lcp = [0usize; MAX_N];
    let mut left_q = [0usize; MAX_N * MAX_N];
    let mut right_q = [0usize; MAX_N * MAX_N];
    for i in 0..n {
        text[i] = input[1 + i];
        if !(0..=127).contains(&text[i]) { return -1; }
        suffix[i] = i;
    }
    for i in 0..m {
        pattern[i] = input[n + 2 + i];
        if !(0..=127).contains(&pattern[i]) { return -1; }
    }
    for i in 1..n {
        let key = suffix[i];
        let mut j = i;
        while j > 0 && suffix_cmp(&text, key, suffix[j - 1], n) < 0 {
            suffix[j] = suffix[j - 1];
            j -= 1;
        }
        suffix[j] = key;
    }
    for i in 0..n - 1 {
        let (a, b) = (suffix[i], suffix[i + 1]);
        let mut k = 0;
        while a + k < n && b + k < n && text[a + k] == text[b + k] { k += 1; }
        lcp[i] = k;
    }
    build_intervals(n, &lcp, &mut left_q, &mut right_q);
    let first = bound(&text, n, &pattern, m, &suffix, &left_q, &right_q, false);
    let last = bound(&text, n, &pattern, m, &suffix, &left_q, &right_q, true);
    let count = last - first;
    let bytes = 8 * (count + 1);
    if output.is_null() || capacity < bytes { return -2; }
    let mut staged = [0u8; MAX_OUTPUT];
    staged[..8].copy_from_slice(&(count as i64).to_le_bytes());
    for i in 0..count { staged[8 * (i + 1)..8 * (i + 2)].copy_from_slice(&(suffix[first + i] as i64).to_le_bytes()); }
    std::ptr::copy_nonoverlapping(staged.as_ptr(), output, bytes);
    bytes as i64
}
