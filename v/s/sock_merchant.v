module sock_merchant

@[export: 'sock_merchant']
pub fn sock_merchant(colors &i64, length usize) i64 {
	if length > 512 { return -1 }
	mut counts := [4096]u64{}
	for index in 0 .. length {
		value := unsafe { colors[index] }
		if value < 0 || value > 4095 { return -1 }
		counts[int(value)]++
	}
	mut pairs := u64(0)
	for color in 0 .. 4096 { pairs += counts[color] / 2 }
	return i64(pairs)
}
