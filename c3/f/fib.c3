module fib;

fn long fib(long n) @export("fib") {
    if (n < 0 || n > 90) return -1;
    long previous = 1, current = 2;
    long i = 0;
    while (i < n) { long next = previous + current; previous = current; current = next; i++; }
    return previous;
}
