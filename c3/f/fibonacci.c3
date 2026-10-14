module fibonacci;

// Portable Fibonacci for the shared signed 64-bit benchmark contract.
fn long fibonacci(long n) @export("fibonacci")
{
    if (n < 0 || n > 92) return -1;
    if (n == 0) return 0;

    long previous = 0;
    long current = 1;
    long index = 1;
    while (index < n) {
        long next = previous + current;
        previous = current;
        current = next;
        index++;
    }
    return current;
}
