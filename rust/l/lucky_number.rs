const MAX_INPUT: i64 = 1_000_000;

/// Preserve the pinned Java rank loop, including counter += 1 each round.
#[no_mangle]
pub extern "C" fn lucky_number(number: i64) -> i64 {
    if !(1..=MAX_INPUT).contains(&number) {
        return -1;
    }
    let mut counter = 2_i64;
    let mut position = number;
    while counter <= position {
        if position % counter == 0 {
            return 0;
        }
        position -= position / counter;
        counter += 1;
    }
    1
}
