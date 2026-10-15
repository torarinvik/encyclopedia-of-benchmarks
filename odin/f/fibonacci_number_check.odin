package fibonacci_number_check

square_i64 :: proc(value: i64) -> bool {
    if value < 0 do return false
    low := i64(0)
    high := i64(3_037_000_499)
    for low <= high {
        middle := low + (high - low) / 2
        square := middle * middle
        if square == value do return true
        if square < value do low = middle + 1
        else do high = middle - 1
    }
    return false
}

@(export)
fibonacci_number_check :: proc "c" (number: i64) -> i64 {
    if number < -1_300_000_000 || number > 1_300_000_000 do return -1
    value := 5 * number * number
    if square_i64(value + 4) || square_i64(value - 4) do return 1
    return 0
}
