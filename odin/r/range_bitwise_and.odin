package range_bitwise_and

// Clear low set bits from the upper endpoint until it meets the lower endpoint.
@(export)
range_bitwise_and :: proc "contextless" (left, right: u64) -> i64 {
	if left > right || right > u64(2_147_483_647) do return -1
	upper := right
	for left < upper { upper &= upper - 1 }
	return i64(upper)
}
