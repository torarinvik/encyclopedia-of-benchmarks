fn get16(p: *const u8, i: usize) -> usize { unsafe { *p.add(i) as usize | ((*p.add(i + 1) as usize) << 8) } }
fn put16(p: *mut u8, i: usize, x: usize) { unsafe { *p.add(i) = x as u8; *p.add(i + 1) = (x >> 8) as u8; } }
fn letter(x: i64) -> bool { (65..=90).contains(&x) || (97..=122).contains(&x) }
fn operator(x: i64) -> bool { matches!(x, 43 | 45 | 42 | 47 | 94) }
#[no_mangle]
pub unsafe extern "C" fn postfix_to_infix(v: *const i64, n: usize, out: *mut u8, cap: usize) -> i64 {
    if v.is_null() || n < 1 || n > 65 { return -1; }
    let a = std::slice::from_raw_parts(v, n);
    if !(0..=64).contains(&a[0]) || n != a[0] as usize + 1 { return -1; }
    if out.is_null() || cap < 8192 { return -2; }
    let count = a[0] as usize; if count == 0 { return 0; }
    if count == 1 { if !letter(a[1]) { return -1; } *out = a[1] as u8; return 1; }
    let mut stack = 0usize; let mut scratch = 256usize;
    for &x in &a[1..] {
        if operator(x) {
            if stack < 2 { return -1; }
            let l = stack - 2; let r = stack - 1;
            let ls = get16(out, l * 4); let ll = get16(out, l * 4 + 2);
            let rs = get16(out, r * 4); let rl = get16(out, r * 4 + 2);
            let start = scratch; *out.add(scratch) = b'('; scratch += 1;
            std::ptr::copy(out.add(ls), out.add(scratch), ll); scratch += ll; *out.add(scratch) = x as u8; scratch += 1;
            std::ptr::copy(out.add(rs), out.add(scratch), rl); scratch += rl; *out.add(scratch) = b')'; scratch += 1;
            put16(out, l * 4, start); put16(out, l * 4 + 2, scratch - start); stack -= 1;
        } else {
            if !letter(x) { return -1; }
            put16(out, stack * 4, scratch); put16(out, stack * 4 + 2, 1); *out.add(scratch) = x as u8; scratch += 1; stack += 1;
        }
        if scratch > cap { return -2; }
    }
    if stack != 1 { return -1; }
    let start = get16(out, 0); let len = get16(out, 2); std::ptr::copy(out.add(start), out, len); len as i64
}
