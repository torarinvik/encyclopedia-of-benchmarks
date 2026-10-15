module range_bitwise_and;

// Clear low set bits from the upper endpoint until it meets the lower endpoint.
fn long range_bitwise_and(ulong left, ulong right) @export("range_bitwise_and") {
    if (left > right || right > 2147483647) return -1;
    ulong upper = right;
    while (left < upper) upper &= upper - 1;
    return (long)upper;
}
