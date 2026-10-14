module abs;

// Return the signed 64-bit magnitude, or -1 when it cannot be represented.
fn long abs_i64(long input) @export("abs_i64")
{
    if (input == -9223372036854775807 - 1) return -1;
    return input < 0 ? -input : input;
}
