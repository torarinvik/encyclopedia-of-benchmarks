module cake_numbers_sequence;

fn long cake_numbers_sequence(long n) @export("cake_numbers_sequence")
{
    if (n < 0 || n > 2000000) return -1;
    return (n * n * n + 5 * n + 6) / 6;
}
