/// Count transitions in the classic Collatz sequence for a bounded input.
export fn collatz(n: i64) i64 {
    if (n < 1 or n > 1_000_000) return -1;
    var current = n;
    var steps: i64 = 0;
    while (current != 1) {
        if (@mod(current, 2) == 0) {
            current = @divTrunc(current, 2);
        } else {
            current = 3 * current + 1;
        }
        steps += 1;
    }
    return steps;
}
