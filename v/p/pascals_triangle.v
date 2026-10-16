@[export: 'pascals_triangle']
pub fn pascals_triangle(v &i64, n usize) i64 {
	unsafe {
		if v == nil || n != 1 || v[0] < 1 || v[0] > 31 { return -1 }
		rows := int(v[0]); mut values := []i64{len: 31, init: 0}; values[0] = 1
		for row in 1 .. rows {
			values[row] = 1
			mut j := row
			for j > 1 { j--; values[j] += values[j - 1] }
		}
		mut hash := i64(0)
		for i in 0 .. rows { hash = (hash * 31 + values[i]) % 1000000007 }
		return hash
	}
}
