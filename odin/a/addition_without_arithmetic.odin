package addition_without_arithmetic

signed_sum_from_bits :: proc "contextless" (bits: u32) -> i64 {
	if bits <= 2_147_483_647 do return i64(bits)
	return i64(bits) - 4_294_967_296
}

@(export)
addition_without_arithmetic :: proc "contextless" (left_encoded, right_encoded: u64) -> i64 {
	if (left_encoded > 2_147_483_647 && left_encoded < 0xFFFF_FFFF_8000_0000) || (right_encoded > 2_147_483_647 && right_encoded < 0xFFFF_FFFF_8000_0000) do return -1
	left_value := signed_sum_from_bits(u32(left_encoded & 0xFFFF_FFFF))
	right_value := signed_sum_from_bits(u32(right_encoded & 0xFFFF_FFFF))
	left := u32(left_encoded & 0xFFFF_FFFF)
	right := u32(right_encoded & 0xFFFF_FFFF)
	for right != 0 {
		carry := left & right
		left = left ~ right
		right = carry << 1
	}
	result := signed_sum_from_bits(left)
	if (left_value < 0) == (right_value < 0) && (result < 0) != (left_value < 0) do return -1
	return result
}
