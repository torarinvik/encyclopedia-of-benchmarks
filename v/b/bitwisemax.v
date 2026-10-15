module bitwisemax

@[export: 'bitwisemax']
pub fn bitwisemax(values &i64, length usize) i64 {
	if length != 2 { return -1 }
	left := unsafe { values[0] }
	right := unsafe { values[1] }
	if left < 0 || left > 2_147_483_647 || right < 0 || right > 2_147_483_647 {
		return -1
	}
	difference := left - right
	choose_right := i64(u32(difference) >> 31)
	return left - choose_right * difference
}
