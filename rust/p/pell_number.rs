#[no_mangle]
pub extern "C" fn pell_number(index: i64) -> i64 {
    if !(0..=50).contains(&index) {
        return -1;
    }
    if index == 0 {
        return 0;
    }
    let mut previous = 0i64;
    let mut current = 1i64;
    for _ in 2..=index {
        let next = 2 * current + previous;
        previous = current;
        current = next;
    }
    current
}
