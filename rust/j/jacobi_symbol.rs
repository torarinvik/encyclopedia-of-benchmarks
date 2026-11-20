const MAX_MODULUS: i64 = 1_000_000_000;

fn reciprocity(mut numerator: i64, mut denominator: i64) -> i64 {
    let mut sign = 1_i64;
    while numerator != 0 {
        while numerator & 1 == 0 {
            numerator /= 2;
            if denominator % 8 == 3 || denominator % 8 == 5 { sign = -sign; }
        }
        if numerator % 4 == 3 && denominator % 4 == 3 { sign = -sign; }
        std::mem::swap(&mut numerator, &mut denominator);
        numerator %= denominator;
    }
    if denominator == 1 { sign } else { 0 }
}

#[no_mangle]
pub unsafe extern "C" fn jacobi_symbol(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length != 2 { return -1; }
    let words = std::slice::from_raw_parts(input, length);
    let numerator = words[0];
    let denominator = words[1];
    if denominator < 1 || denominator > MAX_MODULUS || denominator & 1 == 0 { return -1; }
    if numerator < 0 || numerator >= denominator { return -1; }
    reciprocity(numerator, denominator) + 1
}
