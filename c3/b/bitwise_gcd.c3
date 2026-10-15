module bitwise_gcd;

fn uint trailing_zeros(ulong value)
{
    uint count = 0;
    while ((value & 1) == 0) {
        value >>= 1;
        count += 1;
    }
    return count;
}

fn long bitwise_gcd(ulong left, ulong right) @export("bitwise_gcd")
{
    if (left == 0) return (long)right;
    if (right == 0) return (long)left;

    uint common_twos = trailing_zeros(left | right);
    left >>= trailing_zeros(left);
    while (right != 0) {
        right >>= trailing_zeros(right);
        if (left > right) {
            ulong temp = left;
            left = right;
            right = temp;
        }
        right -= left;
    }
    return (long)(left << common_twos);
}
