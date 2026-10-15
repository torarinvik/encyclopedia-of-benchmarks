module gcd_recursive_euclidean;

// Recursive subtraction-based Euclidean GCD on a bounded positive domain.
fn long gcd_recursive_euclidean_step(ulong left, ulong right)
{
    if (left == right) return (long)left;
    if (left > right) return gcd_recursive_euclidean_step(left - right, right);
    return gcd_recursive_euclidean_step(left, right - left);
}

fn long gcd_recursive_euclidean(ulong left, ulong right) @export("gcd_recursive_euclidean")
{
    if (left == 0 || right == 0 || left > 128 || right > 128) return -1;
    return gcd_recursive_euclidean_step(left, right);
}
