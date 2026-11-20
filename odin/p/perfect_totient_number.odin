package perfect_totient_number

@(export)
perfect_totient_number :: proc "c" (n: i64) -> i64 {
    if n < 3 || n > 65535 do return -1
    value := n
    total: i64 = 0
    for value > 1 {
        result := value
        remaining := value
        factor: i64 = 2
        for factor <= remaining / factor {
            if remaining % factor == 0 {
                for remaining % factor == 0 {
                    remaining /= factor
                }
                result -= result / factor
            }
            factor += 1
        }
        if remaining > 1 do result -= result / remaining
        value = result
        total += value
    }
    if total == n do return 1
    return 0
}
