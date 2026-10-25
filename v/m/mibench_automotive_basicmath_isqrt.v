@[export: 'mibench_automotive_basicmath_isqrt']
pub fn mibench_automotive_basicmath_isqrt(input &i64, length usize) i64 {
	if unsafe { input == nil } || length != 1 { return -1 }
	if unsafe { input[0] < 0 || input[0] > 65535 } { return -1 }
	mut x := u32(unsafe { input[0] })
	mut root := u32(0)
	mut remainder := u32(0)
	for _ in 0 .. 32 {
		remainder = (remainder << 2) + (x >> 30)
		x <<= 2
		root <<= 1
		trial := (root << 1) + 1
		if remainder >= trial {
			remainder -= trial
			root++
		}
	}
	return i64(root)
}
