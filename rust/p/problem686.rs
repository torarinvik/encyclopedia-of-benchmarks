/// Find the nth power of two whose decimal prefix is 123.
const MAX_POSITION: i64 = 678_910;
const LOG10_2: f64 = 0.30102999566398114;
const LOWER_LIMIT: f64 = 0.08990511143939792;
const UPPER_LIMIT: f64 = 0.09342168516223506;
const ROUND_SCALE: f64 = 1_000_000_000_000_000.0;

fn rounded_decimal_part(exponent: i64) -> f64 {
    let logarithm = LOG10_2 * exponent as f64;
    let integer_part = logarithm as i64;
    let scaled = (logarithm - integer_part as f64) * ROUND_SCALE;
    let mut rounded = scaled as i64;
    let remainder = scaled - rounded as f64;
    if remainder > 0.5 || (remainder == 0.5 && rounded % 2 != 0) { rounded += 1; }
    rounded as f64 / ROUND_SCALE
}

#[no_mangle]
pub extern "C" fn problem686(number: i64) -> i64 {
    if number < 1 || number > MAX_POSITION { return -1; }
    let mut power = 90i64;
    let mut position = 0i64;
    let mut previous = 0i64;
    while position < number {
        let difference = rounded_decimal_part(power);
        if difference >= UPPER_LIMIT { power += 93; }
        else if difference < LOWER_LIMIT { power += 196; }
        else { previous = power; power += 196; position += 1; }
    }
    previous
}
