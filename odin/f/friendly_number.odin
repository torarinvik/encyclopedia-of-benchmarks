package friendly_number

sum_divisors :: proc(number: u64) -> i64 {
    sum := i64(0)
    for divisor := u64(1); divisor * divisor <= number; divisor += 1 {
        if number % divisor == 0 {
            sum += i64(divisor)
            other := number / divisor
            if other != divisor do sum += i64(other)
        }
    }
    return sum
}

@(export)
friendly_number :: proc "c" (a, b: u64) -> i64 {
    if a > 1_000_000 || b > 1_000_000 do return -1
    if a == 0 || b == 0 do return 0
    sigma_a, sigma_b := sum_divisors(a), sum_divisors(b)
    if sigma_a * i64(b) == sigma_b * i64(a) do return 1
    return 0
}
