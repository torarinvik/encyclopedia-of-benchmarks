module ones_and_zeros

@[export: 'ones_and_zeros']
pub fn ones_and_zeros(values &i64, length usize) i64 {
	if length < 3 { return -1 }
	count := unsafe { values[0] }; zb := unsafe { values[1] }; ob := unsafe { values[2] }
	if count < 0 || count > 32 || zb < 0 || zb > 32 || ob < 0 || ob > 32 || length != usize(3+2*count) { return -1 }
	mut dp := [33][33]i64{}
	for i in 0 .. int(count) {
		z := unsafe { values[3+2*i] }; o := unsafe { values[4+2*i] }
		if z < 0 || z > 32 || o < 0 || o > 32 { return -1 }
		mut a := int(zb)
		for a >= int(z) { mut b := int(ob); for b >= int(o) { candidate := dp[a-int(z)][b-int(o)] + 1; if candidate > dp[a][b] { dp[a][b] = candidate }; b-- }; a-- }
	}
	return dp[int(zb)][int(ob)]
}
