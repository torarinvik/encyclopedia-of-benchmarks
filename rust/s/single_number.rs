/// XOR reduction for the signed 32-bit single-number contract.
#[no_mangle]
pub extern "C" fn single_number(values: *const i64, length: usize) -> i64 {
    if length == 0 || length > 257 { return -2_147_483_649; }
    let values = unsafe { std::slice::from_raw_parts(values, length) };
    let mut bits = 0_i64;
    for &value in values {
        if !(-2_147_483_648..=2_147_483_647).contains(&value) { return -2_147_483_649; }
        let word = if value < 0 { value + 4_294_967_296 } else { value };
        bits ^= word;
    }
    if bits > 2_147_483_647 { bits - 4_294_967_296 } else { bits }
}
