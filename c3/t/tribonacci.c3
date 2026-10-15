module tribonacci;

// Portable zero-based Tribonacci recurrence for the shared i64 contract.
fn long tribonacci(long n) @export("tribonacci")
{
    if (n < 0 || n > 73) return -1;
    if (n == 0) return 0;
    if (n <= 2) return 1;
    long previous_three = 0;
    long previous_two = 1;
    long previous_one = 1;
    for (long index = 3; index <= n; index++) {
        long next = previous_three + previous_two + previous_one;
        previous_three = previous_two;
        previous_two = previous_one;
        previous_one = next;
    }
    return previous_one;
}
