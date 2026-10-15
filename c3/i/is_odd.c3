module is_odd;

// Return 1 for odd and 0 for even signed 64-bit integers.
fn long is_odd(long value) @export("is_odd")
{
    if (value % 2 != 0) return 1;
    return 0;
}
