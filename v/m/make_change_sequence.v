@[export: 'make_change_sequence']
pub fn make_change_sequence(amount i64) i64 {
	if amount < 0 || amount > 128 { return -1 }
	mut values := [129]i64{}
	values[0] = 1; values[1] = 1; values[2] = 2; values[3] = 2; values[4] = 3
	values[5] = 4; values[6] = 5; values[7] = 6; values[8] = 7; values[9] = 8
	values[10] = 11; values[11] = 12; values[12] = 15; values[13] = 16
	values[14] = 19; values[15] = 22; values[16] = 25
	for n := 17; n <= int(amount); n++ {
		values[n] = values[n - 2] + values[n - 5] - values[n - 7] + values[n - 10] - values[n - 12] - values[n - 15] + values[n - 17] + 1
	}
	return values[int(amount)]
}
