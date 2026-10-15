module fibonacci_number_check

fn square_i64(value i64) bool {
    if value < 0 { return false }
    mut low := i64(0)
    mut high := i64(3037000499)
    for low <= high {
        middle := low + (high - low) / 2
        square := middle * middle
        if square == value { return true }
        if square < value { low = middle + 1 } else { high = middle - 1 }
    }
    return false
}

@[export: 'fibonacci_number_check']
pub fn fibonacci_number_check(number i64) i64 {
    if number < -1300000000 || number > 1300000000 { return -1 }
    value := 5 * number * number
    if square_i64(value + 4) || square_i64(value - 4) { return 1 }
    return 0
}
