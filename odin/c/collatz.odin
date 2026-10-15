package collatz

// Count transitions in the classic Collatz sequence for a bounded input.
@(export)
collatz :: proc "c" (n: i64) -> i64 {
    if n < 1 || n > 1_000_000 do return -1
    current := n
    steps: i64 = 0
    for current != 1 {
        if current % 2 == 0 {
            current /= 2
        } else {
            current = 3 * current + 1
        }
        steps += 1
    }
    return steps
}
