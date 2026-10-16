/// Multiply bounded nonnegative operands with a three-product decimal split.
fn karatsuba_product(left: i64, right: i64) -> i64 {
    if left < 10 || right < 10 { return left * right; }
    let mut largest = left.max(right);
    let mut digits = 1;
    while largest >= 10 { largest /= 10; digits += 1; }
    let mut split = 1i64;
    for _ in 0..digits / 2 { split *= 10; }
    let (left_high, left_low) = (left / split, left % split);
    let (right_high, right_low) = (right / split, right % split);
    let low_product = karatsuba_product(left_low, right_low);
    let high_product = karatsuba_product(left_high, right_high);
    let sum_product = karatsuba_product(left_high + left_low, right_high + right_low);
    high_product * split * split + (sum_product - high_product - low_product) * split + low_product
}

#[no_mangle]
pub unsafe extern "C" fn karatsuba(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length != 2 { return -1; }
    let left = *input;
    let right = *input.add(1);
    if !(0..=1_000_000).contains(&left) || !(0..=1_000_000).contains(&right) { return -1; }
    karatsuba_product(left, right)
}
