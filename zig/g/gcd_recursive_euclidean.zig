/// Recursive subtraction-based Euclidean GCD on a bounded positive domain.
fn gcdRecursiveEuclideanStep(left: u64, right: u64) i64 {
    if (left == right) return @intCast(left);
    if (left > right) return gcdRecursiveEuclideanStep(left - right, right);
    return gcdRecursiveEuclideanStep(left, right - left);
}

export fn gcd_recursive_euclidean(left: u64, right: u64) i64 {
    if (left == 0 or right == 0 or left > 128 or right > 128) return -1;
    return gcdRecursiveEuclideanStep(left, right);
}
