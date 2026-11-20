const MAX_DENOMINATOR: i64 = 1_000_000;
const MAX_CF_SUM: i64 = 60;

fn store_i64_le(output: *mut u8, offset: usize, value: i64) {
    let bytes = value.to_le_bytes();
    unsafe { std::ptr::copy_nonoverlapping(bytes.as_ptr(), output.add(offset), 8); }
}

fn cf_sum(numerator: i64, denominator: i64) -> i64 {
    let (mut n, mut d, mut total) = (numerator, denominator, 0i64);
    while n != 0 {
        let quotient = d / n;
        if quotient > MAX_CF_SUM - total { return -1; }
        total += quotient;
        let remainder = d % n;
        d = n;
        n = remainder;
    }
    total
}

fn alternating_numerator(numerator: i64, denominator: i64, total: i64) -> i64 {
    let (mut n, mut d) = (numerator, denominator);
    let (mut prefix, mut index, mut value) = (0i64, 1i64, 0i64);
    while n != 0 {
        let quotient = d / n;
        prefix += quotient;
        let term = 1i64 << (total - prefix) as u32;
        if index & 1 == 1 { value += term; } else { value -= term; }
        let remainder = d % n;
        d = n;
        n = remainder;
        index += 1;
    }
    value
}

#[no_mangle]
pub unsafe extern "C" fn minkowski_question_mark_rational(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || !(1..=3).contains(&length) { return -1; }
    if length != 2 { return -1; }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    let (p, q) = (values[0], values[1]);
    if p < 0 || q < 1 || q > MAX_DENOMINATOR || p > q { return -1; }
    let total = cf_sum(p, q);
    if total < 0 { return -1; }
    if output.is_null() || capacity < 16 { return -2; }
    let value = alternating_numerator(p, q, total);
    let exponent = if total == 0 { 0 } else { total - 1 };
    store_i64_le(output, 0, value);
    store_i64_le(output, 8, exponent);
    16
}
