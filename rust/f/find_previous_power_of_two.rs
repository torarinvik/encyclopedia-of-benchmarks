/// Repeated-doubling search from the pinned source, bounded to its i32 domain.
#[no_mangle]
pub extern "C" fn find_previous_power_of_two(number: i64) -> i64 {
    if !(0..=i32::MAX as i64).contains(&number) {
        return -1;
    }
    if number == 0 {
        return 0;
    }

    let mut power = 1i64;
    while power <= number {
        power <<= 1;
    }
    if number > 1 { power >> 1 } else { 1 }
}
