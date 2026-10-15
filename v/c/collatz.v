module collatz

// Count transitions in the classic Collatz sequence for a bounded input.
@[export: 'collatz']
pub fn collatz(n i64) i64 {
    if n < 1 || n > 1_000_000 {
        return -1
    }
    mut current := n
    mut steps := i64(0)
    for current != 1 {
        if current % 2 == 0 {
            current /= 2
        } else {
            current = 3 * current + 1
        }
        steps++
    }
    return steps
}
