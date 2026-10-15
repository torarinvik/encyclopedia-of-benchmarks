module square_pyramidal_numbers;

fn long square_pyramidal_numbers(long n) @export("square_pyramidal_numbers") {
    if (n < 0 || n > 2097151) return -1;
    ulong value = (ulong)n;
    ulong numerator = value * (value + 1) * (2 * value + 1);
    return (long)(numerator / 6);
}
