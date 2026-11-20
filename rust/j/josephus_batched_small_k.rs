/// Unwind the logarithmic small-k Josephus recurrence using a bounded frame stack.
#[no_mangle]
pub unsafe extern "C" fn josephus_batched_small_k(values: *const i64, length: usize) -> i64 {
    if values.is_null() || length != 2 { return -1; }
    let values = std::slice::from_raw_parts(values, length);
    let (n0, k) = (values[0], values[1]);
    if !(1..=1_000_000).contains(&n0) || !(1..=32).contains(&k) { return -1; }
    if n0 == 1 { return 0; }
    if k == 1 { return n0 - 1; }
    let mut frames = [0i64; 1024];
    let mut depth = 0usize;
    let mut n = n0;
    while n > 1 {
        if depth == frames.len() { return -1; }
        frames[depth] = n;
        depth += 1;
        n = if n < k { n - 1 } else { n - n / k };
    }
    let mut survivor = 0i64;
    while depth > 0 {
        depth -= 1;
        let m = frames[depth];
        if m < k { survivor = (survivor + k) % m; }
        else {
            survivor -= m % k;
            if survivor < 0 { survivor += m; }
            else { survivor += survivor / (k - 1); }
        }
    }
    survivor
}
