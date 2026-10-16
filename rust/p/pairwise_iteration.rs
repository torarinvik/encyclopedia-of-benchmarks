#[no_mangle]
pub unsafe extern "C" fn pairwise_iteration(v: *const i64, n: usize, out: *mut u8, cap: usize) -> i64 {
    if v.is_null() || n < 1 || n > 129 { return -1; }
    let a = std::slice::from_raw_parts(v, n);
    if !(0..=128).contains(&a[0]) || n != a[0] as usize + 1 { return -1; }
    let count = a[0] as usize;
    if a[1..].iter().any(|&x| !(-1_000_000..=1_000_000).contains(&x)) { return -1; }
    let bytes = count.saturating_sub(1) * 16;
    if bytes > cap || (bytes > 0 && out.is_null()) { return -2; }
    let mut k = 0;
    for i in 0..count.saturating_sub(1) {
        for x in [a[i + 1], a[i + 2]] { for b in x.to_le_bytes() { *out.add(k) = b; k += 1; } }
    }
    bytes as i64
}
