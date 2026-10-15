/// Bit spreading for the pinned positive 32-bit source domain.
#[no_mangle]
pub extern "C" fn next_power_of_two(number: i64) -> i64 {
    if !(1..=1_073_741_824).contains(&number) {
        return -1;
    }
    let mut value = number as u64;
    if (value & (value - 1)) == 0 {
        return number;
    }

    value -= 1;
    value |= value >> 1;
    value |= value >> 2;
    value |= value >> 4;
    value |= value >> 8;
    value |= value >> 16;
    (value + 1) as i64
}
