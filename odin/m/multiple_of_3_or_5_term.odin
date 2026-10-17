package multiple_of_3_or_5_term

@(export)
multiple_of_3_or_5_term :: proc "c" (n: i64) -> i64 {
    if n < 0 || n > 1_000_000_000 do return -1
    if n % 3 == 0 || n % 5 == 0 do return n
    return 0
}
