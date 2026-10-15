/// Compute T(n) = n(n+1)/2 without an overflowing intermediate product.
#[no_mangle]
pub extern "C" fn triangular_number(input: i64) -> i64 {
    if !(0..=4_294_967_295).contains(&input) { return -1; }
    let (left, right) = if input % 2 == 0 {
        (input / 2, input + 1)
    } else {
        (input, (input + 1) / 2)
    };
    left * right
}
