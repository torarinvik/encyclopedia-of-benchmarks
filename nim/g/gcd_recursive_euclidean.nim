## Recursive subtraction-based Euclidean GCD on a bounded positive domain.
proc gcdRecursiveEuclideanStep(left, right: uint64): int64 =
  if left == right:
    return int64(left)
  if left > right:
    return gcdRecursiveEuclideanStep(left - right, right)
  return gcdRecursiveEuclideanStep(left, right - left)

proc gcd_recursive_euclidean*(left, right: uint64): int64
    {.cdecl, exportc: "gcd_recursive_euclidean".} =
  if left == 0 or right == 0 or left > 128 or right > 128:
    return -1
  return gcdRecursiveEuclideanStep(left, right)
