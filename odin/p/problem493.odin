package problem493

choose_ten :: proc(n: i64) -> i64 {
    result := i64(1)
    for i := i64(0); i < 10; i += 1 { result = result * (n - i) / (i + 1) }
    return result
}

@(export)
problem493 :: proc "c" (picks: i64) -> i64 {
    if picks < 0 || picks > 70 do return -1
    denominator := choose_ten(70)
    missing := i64(0)
    if picks <= 60 do missing = choose_ten(70 - picks)
    numerator := 7 * (denominator - missing)
    whole := numerator / denominator
    remainder := numerator % denominator
    fraction := i64(0)
    for i := 0; i < 9; i += 1 { remainder *= 10; fraction = fraction * 10 + remainder / denominator; remainder %= denominator }
    remainder *= 10
    guard := remainder / denominator
    remainder %= denominator
    scaled := whole * 1_000_000_000 + fraction
    if guard > 5 || (guard == 5 && (remainder > 0 || scaled % 2 != 0)) { scaled += 1 }
    return scaled
}
