package count_numbers_divisible

// Count multiples of divisor in the inclusive positive integer interval [first, last].
@(export)
count_numbers_divisible :: proc "c" (first, last, divisor: f64) -> f64 {
    a := i64(first)
    b := i64(last)
    m := i64(divisor)
    return f64(b / m - (a - 1) / m)
}
