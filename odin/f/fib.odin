package fib

@(export)
fib :: proc "c" (n: i64) -> i64 {
    if n < 0 || n > 90 do return -1
    previous := i64(1)
    current := i64(2)
    for i := i64(0); i < n; i += 1 {
        next := previous + current
        previous = current
        current = next
    }
    return previous
}
