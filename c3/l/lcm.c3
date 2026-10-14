module lcm;

// Portable LCM with overflow checked after dividing by the GCD.
fn long lcm(ulong left, ulong right) @export("lcm")
{
    if (left == 0 || right == 0) return 0;
    ulong a = left;
    ulong b = right;
    while (b != 0) {
        ulong remainder = a % b;
        a = b;
        b = remainder;
    }
    ulong reduced = left / a;
    ulong max_result = 9223372036854775807;
    if (reduced > max_result / right) return -1;
    return (long)(reduced * right);
}
