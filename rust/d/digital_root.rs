#[no_mangle]
pub extern "C" fn digital_root(n: i64) -> i64 {
    if n < 0 { return -1; }
    let mut value = n;
    while value >= 10 {
        let mut digits = value;
        let mut total = 0i64;
        while digits > 0 {
            total += digits % 10;
            digits /= 10;
        }
        value = total;
    }
    value
}
