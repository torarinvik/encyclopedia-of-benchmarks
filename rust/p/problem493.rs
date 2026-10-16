fn choose_ten(n: i64) -> i64 {
    let mut result = 1_i64;
    for i in 0..10 { result = result * (n - i) / (i + 1); }
    result
}

#[no_mangle]
pub extern "C" fn problem493(picks: i64) -> i64 {
    if !(0..=70).contains(&picks) { return -1; }
    let denominator = choose_ten(70);
    let missing = if picks > 60 { 0 } else { choose_ten(70 - picks) };
    let numerator = 7 * (denominator - missing);
    let whole = numerator / denominator;
    let mut remainder = numerator % denominator;
    let mut fraction = 0_i64;
    for _ in 0..9 { remainder *= 10; fraction = fraction * 10 + remainder / denominator; remainder %= denominator; }
    remainder *= 10;
    let guard = remainder / denominator;
    remainder %= denominator;
    let mut scaled = whole * 1_000_000_000 + fraction;
    if guard > 5 || (guard == 5 && (remainder > 0 || scaled % 2 != 0)) { scaled += 1; }
    scaled
}
