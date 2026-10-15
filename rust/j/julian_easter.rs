/// Meeus Julian Easter date encoded as YYYYMMDD.
#[no_mangle]
pub extern "C" fn julian_easter(year: i64) -> i64 {
    if !(1..=9999).contains(&year) {
        return -1;
    }
    let a = year % 4;
    let b = year % 7;
    let c = year % 19;
    let d = (19 * c + 15) % 30;
    let e = (2 * a + 4 * b - d + 34) % 7;
    let day_of_year = d + e + 114;
    let month = day_of_year / 31;
    let day = day_of_year % 31 + 1;
    year * 10000 + month * 100 + day
}
