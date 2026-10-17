module matchdimensions

@[export: 'matchdimensions']
pub fn matchdimensions(values &i64, length usize) i64 {
	if unsafe { values == nil } || length != 4 { return -1 }
	unsafe {
		for index in 0 .. 4 {
			if values[index] < 0 || values[index] > 65535 { return -1 }
		}
		return if values[0] == values[2] && values[1] == values[3] { 1 } else { 0 }
	}
}
