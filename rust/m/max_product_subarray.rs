/// Maximum contiguous product with current maximum/minimum tracking.
const INVALID_RESULT: i64 = i64::MIN;

#[no_mangle]
pub extern "C" fn max_product_subarray(values: *const i64, length: usize) -> i64 {
    if length > 9 || (length > 0 && values.is_null()) { return INVALID_RESULT; }
    if length == 0 { return 0; }
    let values = unsafe { std::slice::from_raw_parts(values, length) };
    if !(-10..=10).contains(&values[0]) { return INVALID_RESULT; }
    let (mut max_now, mut min_now, mut max_product) = (values[0], values[0], values[0]);
    for &value in &values[1..] {
        if !(-10..=10).contains(&value) { return INVALID_RESULT; }
        if value < 0 { std::mem::swap(&mut max_now, &mut min_now); }
        max_now = value.max(max_now * value);
        min_now = value.min(min_now * value);
        max_product = max_product.max(max_now);
    }
    max_product
}
