#[no_mangle]
pub extern "C" fn problem9(total: i64) -> i64 {
    if !(3..=1000).contains(&total) {
        return -1;
    }
    let mut a = 1i64;
    while a <= total / 3 {
        let mut b = a + 1;
        while 2 * b < total - a {
            let c = total - a - b;
            if a * a + b * b == c * c {
                return a * b * c;
            }
            b += 1;
        }
        a += 1;
    }
    -1
}
