/// Integer binary exponentiation with Java int wraparound semantics.
fn mul32(x: i64, y: i64) -> i64 {
    let x_low = x % 65_536;
    let x_high = x / 65_536;
    let y_low = y % 65_536;
    let y_high = y / 65_536;
    let cross = (x_low * y_high + x_high * y_low) % 65_536;
    (x_low * y_low + cross * 65_536) % 4_294_967_296
}

#[no_mangle]
pub extern "C" fn binary_pow(first: i64, second: i64) -> i64 {
    if !(-2_147_483_648..=2_147_483_647).contains(&first)
        || !(-2_147_483_648..=2_147_483_647).contains(&second) { return -2_147_483_649; }
    if second <= 0 { return 1; }
    let mut base = if first < 0 { first + 4_294_967_296 } else { first };
    let mut exponent = second;
    let mut result = 1_i64;
    while exponent > 0 {
        if exponent % 2 == 1 { result = mul32(result, base); }
        base = mul32(base, base);
        exponent /= 2;
    }
    if result >= 2_147_483_648 { result - 4_294_967_296 } else { result }
}
