fn next_perm(a: &mut [u8; 7], n: usize) -> bool {
    let mut i = n - 1;
    while i > 0 && a[i - 1] >= a[i] { i -= 1; }
    if i == 0 { return false; }
    let mut j = n - 1;
    while a[j] <= a[i - 1] { j -= 1; }
    a.swap(i - 1, j);
    a[i..n].reverse();
    true
}
fn mix(h: u32, b: u8) -> u32 { (h ^ u32::from(b)).wrapping_mul(16_777_619) }
#[no_mangle]
pub unsafe extern "C" fn permutate_string(v: *const i64, n: usize) -> i64 {
    if v.is_null() || n < 2 || n > 8 { return -1; }
    let x = std::slice::from_raw_parts(v, n);
    if !(1..=7).contains(&x[0]) || n != x[0] as usize + 1 { return -1; }
    let len = x[0] as usize;
    let mut a = [0u8; 7];
    for i in 0..len {
        if !(33..=126).contains(&x[i + 1]) { return -1; }
        a[i] = x[i + 1] as u8;
        if a[..i].contains(&a[i]) { return -1; }
    }
    a[..len].sort_unstable();
    let mut h = 2_166_136_261u32;
    loop {
        for b in &a[..len] { h = mix(h, *b); }
        h = mix(h, 0);
        if !next_perm(&mut a, len) { break; }
    }
    i64::from(h)
}
