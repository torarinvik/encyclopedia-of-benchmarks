module power_of_two;

// Return 1 when n is a positive power of two, otherwise 0.
fn long power_of_two(long n) @export("power_of_two")
{
    if (n <= 0) return 0;
    if ((n & (n - 1)) == 0) return 1;
    return 0;
}
