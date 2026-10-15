/// Clear low set bits from the upper endpoint until it meets the lower endpoint.
export fn range_bitwise_and(left: u64, right_value: u64) i64 {
    if (left > right_value or right_value > 2_147_483_647) return -1;
    var right = right_value;
    while (left < right) right &= right - 1;
    return @intCast(right);
}
