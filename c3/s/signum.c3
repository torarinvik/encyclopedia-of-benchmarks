module signum;

// Sign of a signed 64-bit integer.
fn long signum(long value) @export("signum")
{
    if (value > 0) return 1;
    if (value < 0) return -1;
    return 0;
}
