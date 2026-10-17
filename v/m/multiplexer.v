module multiplexer

@[export: 'multiplexer']
pub fn multiplexer(values &i64, length usize) i64 {
	unsafe {
		if values == nil || length != 3 { return -1 }
		input0 := values[0]
		input1 := values[1]
		select := values[2]
		if (input0 != 0 && input0 != 1) || (input1 != 0 && input1 != 1) ||
			(select != 0 && select != 1) { return -1 }
		if select == 1 { return input1 }
		return input0
	}
}
