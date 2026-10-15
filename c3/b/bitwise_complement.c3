module bitwise_complement;

// Complement only the significant binary digits of a nonnegative integer.
fn long bitwise_complement(long n) @export("bitwise_complement")
{
    if (n < 0 || n > 2147483647) return -1;
    if (n == 0) return 1;
    ulong value = (ulong)n;
    ulong mask = 0ul;
    while (value != 0ul) {
        mask = (mask << 1) | 1ul;
        value = value >> 1;
    }
    return n ^ (long)mask;
}
