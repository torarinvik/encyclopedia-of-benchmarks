const MAX_MODULUS: i64 = 100_000;
const RESULT_OFFSET: i64 = 29_999_700_001;

fn gcd(mut left: i64, mut right: i64) -> i64 {
    while right != 0 {
        let remainder = left % right;
        left = right;
        right = remainder;
    }
    left
}

fn scaled_sum(numerator: i64, modulus: i64) -> i64 {
    if modulus == 1 { return 0; }
    let tail = scaled_sum(modulus % numerator, numerator);
    let top = numerator * numerator + modulus * modulus + 1
        - 3 * numerator * modulus - modulus * tail;
    top / numerator
}

#[no_mangle]
pub unsafe extern "C" fn dedekind_sum_reciprocity(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length != 2 { return -1; }
    let words = std::slice::from_raw_parts(input, length);
    let numerator = words[0];
    let modulus = words[1];
    if modulus < 1 || modulus > MAX_MODULUS || numerator < 0 || numerator >= modulus
        || gcd(numerator, modulus) != 1 { return -1; }
    RESULT_OFFSET + scaled_sum(numerator, modulus)
}
