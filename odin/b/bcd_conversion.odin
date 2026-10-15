package bcd_conversion

INVALID_RESULT :: i64 = -1

@(export)
bcd_conversion :: proc "c" (decimal: i64) -> i64 {
	if decimal < 0 || decimal > 9999 do return INVALID_RESULT
	value := decimal
	bcd := i64(0)
	shift := i64(0)
	for value > 0 {
		digit := value % 10
		bcd |= digit << (shift * 4)
		value /= 10
		shift += 1
	}
	return bcd
}
