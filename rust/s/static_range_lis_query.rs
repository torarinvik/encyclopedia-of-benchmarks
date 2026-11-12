const MAX_N: usize = 128;
const MAX_Q: usize = 32;

fn lower_bound(values: &[i64; MAX_N], count: usize, value: i64) -> usize {
    let (mut lo, mut hi) = (0, count);
    while lo < hi {
        let mid = lo + (hi - lo) / 2;
        if values[mid] < value { lo = mid + 1; } else { hi = mid; }
    }
    lo
}
unsafe fn put_i64_le(output: *mut u8, offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 { *output.add(offset + byte) = (bits >> (byte * 8)) as u8; }
}

#[no_mangle]
pub unsafe extern "C" fn static_range_lis_query(input: *const i64, length: usize,
        output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 2 || length > 195 { return -1; }
    let n64 = *input;
    let q64 = *input.add(1);
    if n64 < 1 || n64 > 128 || q64 < 1 || q64 > 32 { return -1; }
    let n = n64 as usize;
    let q = q64 as usize;
    if length != 2 + n + 2 * q { return -1; }
    let mut permutation = [0i64; MAX_N];
    let mut seen = [false; MAX_N];
    for i in 0..n {
        let value = *input.add(2 + i);
        if value < 0 || value >= n64 || seen[value as usize] { return -1; }
        seen[value as usize] = true;
        permutation[i] = value;
    }
    let mut left = [0i64; MAX_Q];
    let mut right = [0i64; MAX_Q];
    let mut offset = 2 + n;
    for k in 0..q {
        left[k] = *input.add(offset);
        right[k] = *input.add(offset + 1);
        offset += 2;
        if left[k] < 0 || left[k] > right[k] || right[k] > n64 { return -1; }
    }
    let mut answers = [0i64; MAX_Q];
    let mut tails = [0i64; MAX_N];
    for k in 0..q {
        let mut count = 0usize;
        for i in left[k] as usize..right[k] as usize {
            let at = lower_bound(&tails, count, permutation[i]);
            tails[at] = permutation[i];
            if at == count { count += 1; }
        }
        answers[k] = count as i64;
    }
    let bytes = 8 * q;
    if output.is_null() || capacity < bytes { return -2; }
    for k in 0..q { put_i64_le(output, 8 * k, answers[k]); }
    bytes as i64
}
