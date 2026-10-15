#[no_mangle]
pub extern "C" fn padovan_sequence(index: i64) -> i64 {
    if !(0..=156).contains(&index) {
        return -1;
    }
    if index <= 2 {
        return 1;
    }

    let (mut a, mut b, mut c) = (1i64, 1i64, 1i64);
    let mut result = 0i64;
    for _ in 3..=index {
        result = a + b;
        a = b;
        b = c;
        c = result;
    }
    result
}
