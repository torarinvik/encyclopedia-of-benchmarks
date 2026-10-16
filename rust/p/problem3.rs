/// Return the largest prime factor for a supported positive input.
#[no_mangle]
pub extern "C" fn problem3(number: i64) -> i64 {
    if !(2..=600_851_475_143).contains(&number) {
        return -1;
    }
    let mut remaining = number;
    let mut largest = 1i64;
    let mut factor = 2i64;
    while factor <= remaining / factor {
        if remaining % factor == 0 {
            largest = factor;
            remaining /= factor;
        } else {
            factor += 1;
        }
    }
    if remaining > 1 { remaining } else { largest }
}
