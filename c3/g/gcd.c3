module gcd;

// Portable iterative Euclidean GCD; workload values fit signed 64-bit.
fn long gcd(ulong left, ulong right) @export("gcd")
{
    while (right != 0) {
        ulong remainder = left % right;
        left = right;
        right = remainder;
    }
    return (long)left;
}
