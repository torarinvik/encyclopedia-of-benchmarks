module problem137;

fn long problem137(long n) @export("problem137") {
    if (n < 1 || n > 23) return -1;
    long previous = 1;
    long current = 1;
    for (long index = 0; index < 2 * n - 1; index++) {
        long next = previous + current;
        previous = current;
        current = next;
    }
    return previous * current;
}
