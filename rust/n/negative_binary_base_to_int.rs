/// Interpret most-significant-first bits in radix -2 with checked i64 folding.
#[no_mangle]
pub unsafe extern "C" fn negative_binary_base_to_int(input: *const i64, length: usize) -> i64 {
    if input.is_null() || !(1..=63).contains(&length) { return -1; }
    let mut value = 0i64;
    for index in 0..length {
        let bit = *input.add(index);
        if bit != 0 && bit != 1 { return -1; }
        if value > 4611686018427387904 || value < -4611686018427387903 { return -1; }
        value = value * -2 + bit;
    }
    value
}
