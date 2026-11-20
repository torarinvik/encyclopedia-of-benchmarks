const BASE: i64 = 1_000_000_000;
const MAX_LIMBS: usize = 8;
type Limbs = [i64; MAX_LIMBS];

fn trim(x: &Limbs, mut n: usize) -> usize { while n > 0 && x[n - 1] == 0 { n -= 1; } n }
fn parse(text: &[i64], x: &mut Limbs) -> usize {
    let mut n = 0;
    for &byte in text {
        let mut carry = byte - 48;
        for limb in x.iter_mut().take(n) { carry += *limb * 10; *limb = carry % BASE; carry /= BASE; }
        if carry != 0 { x[n] = carry; n += 1; }
        if n == 0 { n = 1; }
    }
    trim(x, n)
}
fn compare(a: &Limbs, na: usize, b: &Limbs, nb: usize) -> i32 {
    if na != nb { return if na > nb { 1 } else { -1 }; }
    for i in (0..na).rev() { if a[i] != b[i] { return if a[i] > b[i] { 1 } else { -1 }; } }
    0
}
fn divide(a: &Limbs, na: usize, b: &Limbs, nb: usize, q: &mut Limbs, r: &mut Limbs) -> (usize, usize) {
    if na == 0 { return (0, 0); }
    if compare(a, na, b, nb) < 0 { *r = *a; return (0, na); }
    if nb == 1 {
        let mut rem = 0;
        for i in (0..na).rev() { let cur = rem * BASE + a[i]; q[i] = cur / b[0]; rem = cur % b[0]; }
        if rem != 0 { r[0] = rem; return (trim(q, na), 1); }
        return (trim(q, na), 0);
    }
    let mut v = [0_i64; MAX_LIMBS]; let mut u = [0_i64; MAX_LIMBS + 1];
    let scale = BASE / (b[nb - 1] + 1); let mut carry = 0;
    for i in 0..nb { let cur = b[i] * scale + carry; v[i] = cur % BASE; carry = cur / BASE; }
    carry = 0;
    for i in 0..na { let cur = a[i] * scale + carry; u[i] = cur % BASE; carry = cur / BASE; }
    u[na] = carry;
    let width = na - nb + 1;
    for step in (0..width).rev() {
        let numerator = u[step + nb] * BASE + u[step + nb - 1];
        let mut estimate = numerator / v[nb - 1]; let mut rem_estimate = numerator % v[nb - 1];
        if estimate >= BASE { estimate = BASE - 1; rem_estimate = numerator - estimate * v[nb - 1]; }
        while rem_estimate < BASE && estimate * v[nb - 2] > rem_estimate * BASE + u[step + nb - 2] {
            estimate -= 1; rem_estimate += v[nb - 1];
        }
        let mut borrow = 0;
        for i in 0..nb {
            let product = estimate * v[i] + borrow; let low = product % BASE; borrow = product / BASE;
            let mut difference = u[step + i] - low;
            if difference < 0 { difference += BASE; borrow += 1; }
            u[step + i] = difference;
        }
        let top = u[step + nb] - borrow;
        if top < 0 {
            estimate -= 1; carry = 0;
            for i in 0..nb {
                let mut sum = u[step + i] + v[i] + carry;
                if sum >= BASE { sum -= BASE; carry = 1; } else { carry = 0; }
                u[step + i] = sum;
            }
            u[step + nb] = top + carry;
        } else { u[step + nb] = top; }
        q[step] = estimate;
    }
    carry = 0;
    for i in (0..nb).rev() { let cur = carry * BASE + u[i]; r[i] = cur / scale; carry = cur % scale; }
    (trim(q, width), trim(r, nb))
}
fn emit(x: &Limbs, n_input: usize, output: &mut [u8], mut at: usize) -> usize {
    let n = trim(x, n_input);
    if n == 0 { output[at] = b'0'; return at + 1; }
    let mut value = x[n - 1]; let mut power = 1_i64;
    while value / power >= 10 { power *= 10; }
    while power > 0 { output[at] = b'0' + (value / power % 10) as u8; at += 1; power /= 10; }
    for i in (0..n - 1).rev() {
        value = x[i]; power = BASE / 10;
        while power > 0 { output[at] = b'0' + (value / power % 10) as u8; at += 1; power /= 10; }
    }
    at
}
unsafe fn store_output(output: *mut u8, result: &[u8]) { for (i, byte) in result.iter().enumerate() { *output.add(i) = *byte; } }

#[no_mangle]
pub unsafe extern "C" fn knuth_big_integer_division(input: *const i64, length: usize,
    output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 4 || length > 130 { return -1; }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    if !(1..=64).contains(&values[0]) || !(1..=64).contains(&values[1]) { return -1; }
    let na_text = values[0] as usize; let nb_text = values[1] as usize;
    if length != 2 + na_text + nb_text { return -1; }
    let a_text = &values[2..2 + na_text]; let b_text = &values[2 + na_text..];
    for &byte in a_text.iter().chain(b_text) { if !(48..=57).contains(&byte) { return -1; } }
    if (na_text > 1 && a_text[0] == 48) || (nb_text > 1 && b_text[0] == 48) || (nb_text == 1 && b_text[0] == 48) { return -1; }
    let mut a = [0_i64; MAX_LIMBS]; let mut b = [0_i64; MAX_LIMBS];
    let mut q = [0_i64; MAX_LIMBS]; let mut r = [0_i64; MAX_LIMBS];
    let na = parse(a_text, &mut a); let nb = parse(b_text, &mut b);
    let (nq, nr) = divide(&a, na, &b, nb, &mut q, &mut r);
    let mut result = [0_u8; 129]; let mut bytes = emit(&q, nq, &mut result, 0);
    result[bytes] = b':'; bytes += 1; bytes = emit(&r, nr, &mut result, bytes);
    if output.is_null() || capacity < bytes { return -2; }
    unsafe { store_output(output, &result[..bytes]); }
    bytes as i64
}
