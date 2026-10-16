package isautomorphic

// Preserve the Go source's direct square-and-last-digit loop.
@(export)
isautomorphic :: proc "c" (n: i64) -> i64 {
    max_safe: i64 = 3037000499
    if n < -max_safe || n > max_safe {
        return -1
    }
    if n < 0 {
        return 0
    }

    square := n * n
    remaining := n
    for remaining > 0 {
        if remaining % 10 != square % 10 {
            return 0
        }
        remaining /= 10
        square /= 10
    }
    return 1
}
