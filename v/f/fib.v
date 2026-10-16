module fib

@[export: 'fib']
pub fn fib(n i64) i64 {
    if n < 0 || n > 90 { return -1 }
    mut previous := i64(1)
    mut current := i64(2)
    for _ in 0 .. n {
        next := previous + current
        previous = current
        current = next
    }
    return previous
}
