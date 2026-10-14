/// Positive powers of four within the signed 32-bit source domain.
#[no_mangle]
pub extern "C" fn power_of_four(value: i64) -> i64 {
    if !(-2_147_483_648..=2_147_483_647).contains(&value) { return -1; }
    if value <= 0 || (value & (value - 1)) != 0 { return 0; }
    if (value & 0x5555_5555) != 0 { 1 } else { 0 }
}
