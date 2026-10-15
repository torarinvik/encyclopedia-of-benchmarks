module count_numbers_divisible

// Count multiples of divisor in the inclusive positive integer interval [first, last].
@[export: 'count_numbers_divisible']
pub fn count_numbers_divisible(first f64, last f64, divisor f64) f64 {
    a := i64(first)
    b := i64(last)
    m := i64(divisor)
    return f64(b / m - (a - 1) / m)
}
