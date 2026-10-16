@[export: 'parenthesis']
pub fn parenthesis(v &i64, n usize) i64 {
	unsafe {
		if v == nil || n < 1 || n > 129 || v[0] < 0 || v[0] > 128 || n != usize(v[0] + 1) { return -1 }
		mut balance := i64(0)
		for i in 1 .. int(n) {
			x := v[i]; if x < 0 || x > 127 { return -1 }
			if x == 40 { balance++ } else if x == 41 { balance--; if balance < 0 { return 0 } }
		}
		return i64(balance == 0)
	}
}
