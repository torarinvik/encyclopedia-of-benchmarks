module range_bitwise_and

// Clear low set bits from the upper endpoint until it meets the lower endpoint.
@[export: 'range_bitwise_and']
pub fn range_bitwise_and(left u64, right u64) i64 {
	if left > right || right > u64(2_147_483_647) { return -1 }
	mut upper := right
	for left < upper { upper &= upper - u64(1) }
	return i64(upper)
}
