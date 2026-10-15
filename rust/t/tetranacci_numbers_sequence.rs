#[no_mangle]
pub extern "C" fn tetranacci_numbers_sequence(index: i64) -> i64 {
    if !(0..=68).contains(&index) {
        return -1;
    }
    let (mut a, mut b, mut c, mut d) = (1i64, 1i64, 1i64, 1i64);
    if index <= 3 {
        return 1;
    }
    for _ in 4..=index {
        let next = a + b + c + d;
        a = b;
        b = c;
        c = d;
        d = next;
    }
    d
}
