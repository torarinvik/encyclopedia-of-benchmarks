module bcd_conversion

const invalid_result = i64(-1)

@[export: 'bcd_conversion']
pub fn bcd_conversion(decimal i64) i64 {
	if decimal < 0 || decimal > 9999 { return invalid_result }
	mut value := decimal
	mut bcd := i64(0)
	mut shift := i64(0)
	for value > 0 {
		digit := value % 10
		bcd |= digit << (shift * 4)
		value /= 10
		shift++
	}
	return bcd
}
