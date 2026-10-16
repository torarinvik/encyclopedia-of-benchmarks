package problem301

@(export)
problem301 :: proc "c" (exponent: i64) -> i64 {
    if exponent < 0 || exponent > 30 do return -1
    previous, current := i64(0), i64(1)
    for index := i64(0); index < exponent + 2; index += 1 {
        next := previous + current
        previous = current
        current = next
    }
    return previous - exponent % 2
}
