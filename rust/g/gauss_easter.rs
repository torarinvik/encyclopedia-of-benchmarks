fn positive_mod(value: i64, modulus: i64) -> i64 {
    value.rem_euclid(modulus)
}

#[no_mangle]
pub extern "C" fn gauss_easter(year: i64) -> i64 {
    if !(1..=9999).contains(&year) { return -1; }
    let a = year % 19;
    let b = year % 4;
    let c = year % 7;
    let century = year / 100;
    let lunar_correction = (13 + 8 * century) / 25;
    let moon_q = positive_mod(60 - 4 * lunar_correction + 3 * century, 120);
    let start_q = positive_mod(16 + 3 * century, 28);
    let add_q = positive_mod(76 * a + moon_q, 120);
    let sunday_q = positive_mod(8 * b + 16 * c + start_q + 6 * add_q, 28);
    let (month, day) = if add_q == 116 && sunday_q == 24 { (4, 19) }
        else if add_q == 112 && sunday_q == 24 { (4, 18) }
        else {
            let march_day = 22 + (add_q + sunday_q) / 4;
            if march_day <= 31 { (3, march_day) } else { (4, march_day - 31) }
        };
    year * 10000 + month * 100 + day
}
