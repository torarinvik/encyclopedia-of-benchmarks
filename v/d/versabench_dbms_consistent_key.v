module versabench_dbms_consistent_key

@[export: 'versabench_dbms_consistent_key']
pub fn versabench_dbms_consistent_key(values &i64, length usize) i64 {
	unsafe {
		if values == nil || length < 1 || length > 17 || length != 16 { return -1 }
		for box in 0 .. 2 {
			base := box * 8
			for d in 0 .. 4 {
				lower := values[base+d]; upper := values[base+4+d]
				if lower < -8 || lower > 8 || upper < -8 || upper > 8 || lower > upper { return -1 }
			}
		}
		for d in 0 .. 4 { if values[d] > values[12+d] || values[8+d] > values[4+d] { return 0 } }
		return 1
	}
}
