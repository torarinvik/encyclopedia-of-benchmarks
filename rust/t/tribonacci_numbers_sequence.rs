/// Zero-based Tribonacci sequence with source seeds 1, 1, 1.
#[no_mangle]
pub extern "C" fn tribonacci_numbers_sequence(index: i64) -> i64 {
    if !(0..=60).contains(&index) {
        return -1;
    }
    if index < 3 {
        return 1;
    }

    let mut first = 1i64;
    let mut second = 1i64;
    let mut third = 1i64;
    for _ in 3..=index {
        let next = first + second + third;
        first = second;
        second = third;
        third = next;
    }
    third
}
