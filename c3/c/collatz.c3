module collatz;

// Count transitions in the classic Collatz sequence for a bounded input.
fn long collatz(long n) @export("collatz")
{
    if (n < 1 || n > 1000000) return -1;
    long steps = 0;
    while (n != 1) {
        if (n % 2 == 0) {
            n /= 2;
        } else {
            n = 3 * n + 1;
        }
        steps += 1;
    }
    return steps;
}
