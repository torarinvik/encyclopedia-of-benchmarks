package problem401

MAX_LIMIT :: i64(1000)
MOD_LIMIT :: i64(1_000_000_000)

contains :: proc(value: i64, divisors: []i64, length: i64) -> bool {
    for i := i64(0); i < length; i += 1 { if divisors[int(i)] == value do return true }
    return false
}
get_divisors :: proc(number: i64, divisors: []i64) -> i64 {
    if number == 1 { divisors[0] = 1; return 1 }
    count := i64(0)
    for divisor := i64(1); divisor * divisor <= number + 1; divisor += 1 {
        if number % divisor != 0 do continue
        quotient := number / divisor
        if !contains(divisor, divisors, count) { divisors[int(count)] = divisor; count += 1 }
        if !contains(quotient, divisors, count) { divisors[int(count)] = quotient; count += 1 }
    }
    return count
}
sigma2_source :: proc(number: i64) -> i64 {
    divisors: [128]i64 = {}
    count := get_divisors(number, divisors[:])
    sum := i64(0)
    for i := 1; i < count; i += 1 { sum += (divisors[int(i)] * divisors[int(i)]) % MOD_LIMIT }
    return sum % MOD_LIMIT
}

@(export)
problem401 :: proc "c" (limit: i64) -> i64 {
    if limit < 0 || limit > MAX_LIMIT do return -1
    sum := i64(0)
    for number := i64(0); number <= limit; number += 1 { sum += sigma2_source(number) }
    return sum % MOD_LIMIT
}
