/// Search odd divisors for the first source repunit length exceeding limit.
const MAX_LIMIT: i64 = 1_000_000;

fn least_divisible_repunit(divisor: i64) -> i64 {
    if divisor % 5 == 0 || divisor % 2 == 0 { return 0; }
    let mut repunit = 1i64;
    let mut repunit_index = 1i64;
    while repunit != 0 {
        repunit = (10 * repunit + 1) % divisor;
        repunit_index += 1;
    }
    repunit_index
}

#[no_mangle]
pub extern "C" fn problem129(limit: i64) -> i64 {
    if limit < 1 || limit > MAX_LIMIT { return -1; }
    let mut divisor = limit - 1;
    if divisor % 2 == 0 { divisor += 1; }
    while least_divisible_repunit(divisor) <= limit { divisor += 2; }
    divisor
}
