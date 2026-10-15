module binary_multiplication;

// Multiply nonnegative operands with shift-and-add; inputs are at most 1e9.
fn long binary_multiplication(ulong a, ulong b) @export("binary_multiplication")
{
    ulong result = 0;
    while (b > 0) {
        if ((b & 1) != 0) {
            result += a;
        }
        a += a;
        b >>= 1;
    }
    return (long)result;
}
