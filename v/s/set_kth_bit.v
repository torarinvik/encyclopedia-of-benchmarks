module set_kth_bit

const InvalidResult = i64(-1)

@[export: 'set_kth_bit']
pub fn set_kth_bit(input &i64, length usize) i64 {
	if unsafe { input == nil } || length != 2 { return InvalidResult }
	number, bit := input[0], input[1]
	if number < 0 || number > 2147483647 || bit < 0 || bit > 30 { return InvalidResult }
	return number | (i64(1) << u64(bit))
}
