package problem10_ruby_prefix

is_prime_value :: proc(number: i64) -> bool {
    if number > 1 && number < 4 do return true
    if number < 2 || number % 2 == 0 || number % 3 == 0 do return false
    for divisor := i64(5); divisor * divisor <= number; divisor += 6 {
        if number % divisor == 0 || number % (divisor + 2) == 0 do return false
    }
    return true
}

@(export)
problem10_ruby_prefix :: proc "c" (max_total: i64) -> i64 {
    if max_total < 0 || max_total > 2_000_000 do return -1
    sum := i64(1)
    value := i64(1)
    for number := i64(2); number < max_total && value < max_total; number += 1 {
        if is_prime_value(number) {
            value += number
            if value < max_total do sum = value
        }
    }
    return sum
}
