module is_even;

// Return 1 for even and 0 for odd signed 64-bit integers.
fn long is_even(long value) @export("is_even")
{
    if (value % 2 == 0) return 1;
    return 0;
}
