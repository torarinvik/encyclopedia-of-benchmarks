module problem10_ruby_prefix

fn is_prime_value(number i64) bool {
    if number > 1 && number < 4 { return true }
    if number < 2 || number % 2 == 0 || number % 3 == 0 { return false }
    mut divisor := i64(5)
    for divisor * divisor <= number {
        if number % divisor == 0 || number % (divisor + 2) == 0 { return false }
        divisor += 6
    }
    return true
}

@[export: 'problem10_ruby_prefix']
pub fn problem10_ruby_prefix(max_total i64) i64 {
    if max_total < 0 || max_total > 2_000_000 { return -1 }
    mut sum := i64(1)
    mut value := i64(1)
    mut number := i64(2)
    for number < max_total && value < max_total {
        if is_prime_value(number) {
            value += number
            if value < max_total { sum = value }
        }
        number++
    }
    return sum
}
