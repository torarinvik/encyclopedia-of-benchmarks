#[no_mangle]
pub extern "C" fn perrin_number(index: i64) -> i64 {
    if !(0..=155).contains(&index) {
        return -1;
    }
    match index {
        0 => return 3,
        1 => return 0,
        2 => return 2,
        _ => {}
    }
    let (mut a, mut b, mut c) = (3i64, 0i64, 2i64);
    let mut result = 0i64;
    for _ in 3..=index {
        result = a + b;
        a = b;
        b = c;
        c = result;
    }
    result
}
