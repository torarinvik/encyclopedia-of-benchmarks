package lucas_series
@(export)
lucas_series :: proc "c" (n: i64) -> i64 {
    if n < 0 || n > 90 do return -1
    if n == 0 do return 2
    previous := i64(2)
    current := i64(1)
    for index := i64(2); index <= n; index += 1 {
        next := previous + current
        previous = current
        current = next
    }
    return current
}
