module binary_to_decimal;

// Convert a packed most-significant-first binary digit array to signed i64.
fn long binary_to_decimal(long* bits, usz length) @export("binary_to_decimal")
{
    if (length == 0 || length > 63) return -1;
    ulong value = 0;
    for (usz index = 0; index < length; index++) {
        if (bits[index] != 0 && bits[index] != 1) return -1;
        value = value * 2 + (ulong)bits[index];
    }
    return (long)value;
}
