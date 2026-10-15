module jacobsthal_number;

fn long jacobsthal_number(long n) @export("jacobsthal_number")
{
    if (n < 0 || n > 64) return -1;
    if (n == 0) return 0;
    long previous = 0;
    long current = 1;
    for (long index = 2; index <= n; index++) {
        long next = current + 2 * previous;
        previous = current;
        current = next;
    }
    return current;
}
