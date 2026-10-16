#[no_mangle]
pub unsafe extern "C" fn polybius(v: *const i64, n: usize, out: *mut u8, cap: usize) -> i64 {
    if v.is_null() || n < 1 || n > 65 { return -1; }
    let a = std::slice::from_raw_parts(v, n);
    if !(0..=64).contains(&a[0]) || n != a[0] as usize + 1 { return -1; }
    let count = a[0] as usize; let needed = count * 2;
    if needed > cap || (needed > 0 && out.is_null()) { return -2; }
    let mut k = 0;
    for &raw in &a[1..] { let mut x = raw; if (97..=122).contains(&x) { x -= 32; } if !(65..=90).contains(&x) || x == 74 { return -1; }
        let mut index = (x - 65) as usize; if x > 74 { index -= 1; }
        *out.add(k) = b'A' + (index / 5) as u8; *out.add(k + 1) = b'A' + (index % 5) as u8; k += 2;
    }
    needed as i64
}
